using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using GalaSoft.MvvmLight;
using GalaSoft.MvvmLight.Command;

namespace InheritanceInsertion.ViewModel
{
    public class ProjectViewModel : ObservableObject
    {
        public static readonly string[] DataTypes =
        {
            "inheritance", "downcall", "external-reuse", "internal-reuse",
            "subtype", "super", "generic", "types", "loc", "dynamic"
        };

        private readonly string _basePath;

        private bool _isSelected;

        public bool IsSelected
        {
            get { return _isSelected; }
            set { Set("IsSelected", ref _isSelected, value); }
        }

        public int NumberOfModules
        {
            get { return _modules.Count; }
        }

        private readonly Dictionary<string, FileViewModel> _files = new Dictionary<string, FileViewModel>();
        private List<ProjectViewModel> _modules;
        private readonly string _language;
        private readonly string _name;
        private readonly RelayCommand _uploadCommand;
        private string _currentlyLoading;

        private bool _isLoading;
        private readonly string _sourceCodeType;
        private readonly string _moduleName;

        public ProjectViewModel(string basePath, string name, string language, string sourceCodeType, string moduleName)
        {
            _basePath = basePath;
            _name = name;
            _language = language;
            _modules = new List<ProjectViewModel> {this};
            this._sourceCodeType = sourceCodeType;
            _moduleName = moduleName;
            _uploadCommand = new RelayCommand(BeginUpload, () => FileDictionary["inheritance"].Exists);
            foreach (string dataType in DataTypes)
            {
                FileDictionary.Add(dataType, new FileViewModel(dataType));
            }
        }

        public bool IsLoading
        {
            get { return _isLoading; }
            set { Set(() => IsLoading, ref _isLoading, value); }
        }

        public string CurrentlyLoading
        {
            get { return _currentlyLoading; }
            set { Set(() => CurrentlyLoading, ref _currentlyLoading, value); }
        }


        public List<FileViewModel> Files
        {
            get { return FileDictionary.Values.ToList(); }
        }

        public string Name
        {
            get { return _name; }
        }
 
        public string Language
        {
            get { return _language; }
        }

        public RelayCommand UploadCommand
        {
            get { return _uploadCommand; }
        }

        public Dictionary<string, FileViewModel> FileDictionary
        {
            get { return _files; }
        }

        public string SourceCodeType
        {
            get { return _sourceCodeType; }
        }

        public string ModuleName
        {
            get { return _moduleName; }
        }

        public List<ProjectViewModel> Modules
        {
            get { return _modules; }
        }

        public bool Exists { get; set;}

        private async void BeginUpload()
        {
            await UploadDataAsync();
        }

        public async Task UploadDataAsync()
        {
            IsLoading = true;
            var mergedName = _name; ;
            var proj = new ProjectInserter();
            CurrentlyLoading = "Creating Project...";
            var projects = _modules.ToList();
            int linesOfCode = 0, linesOfComment = 0, linesOfBlank = 0;
            foreach (var other in projects)
            {
                int otherLoc, otherComment, otherBlank;
                other.TryGetLineOfCodeData(out otherLoc, out otherComment, out otherBlank);
                linesOfCode += otherLoc;
                linesOfComment += otherComment;
                linesOfBlank += otherBlank;
            }

            int projectId = await proj.InsertProjectAsync(mergedName, _language, linesOfCode, linesOfComment, linesOfBlank, SourceCodeType);
            var typeLocs = new HashSet<string>();
            CurrentlyLoading = "Creating Relations...";
            var systemtypes = new Dictionary<string, bool>();
            foreach (var projectViewModel in projects)
            {
                foreach (string line in File.ReadLines(projectViewModel.GetFilePath("types")).Skip(1))
                {
                    string[] split = line.Split(';');
                    typeLocs.Add(split[0]);
                    bool systemType;
                    var current = systemtypes.TryGetValue(split[0], out systemType) && systemType;
                    systemtypes[split[0]] = bool.Parse(split[1]) || current;
                }
                
            }
            var types = new TypeData();
            Dictionary<string, int> dictionary = await types.CreateTypeDictionary(projectId, typeLocs.ToList(), systemtypes);
            var relInsertion = new RelationInserter(projectId);
            foreach (var projectViewModel in projects)
            {
                foreach (string line in File.ReadLines(projectViewModel.GetFilePath("inheritance")).Skip(1))
                {
                    string[] split = line.Split(';');
                    relInsertion.AddItem(split[0], dictionary[split[1]], dictionary[split[2]], Convert.ToBoolean(split[3]),
                        Convert.ToBoolean(split[4]), Convert.ToBoolean(split[5]), Convert.ToBoolean(split[6]));
                }
            }

            await relInsertion.SaveAsync();
            CurrentlyLoading = "Loading Super..";
            await UploadSuperAsync(projectId, dictionary, projects);
            CurrentlyLoading = "Loading Internal Reuse..";
            await UploadInternalReuseAsync(projectId, dictionary, projects);
            CurrentlyLoading = "Loading External Reuse..";
            await UploadExternalReuseAsync(projectId, dictionary, projects);
            CurrentlyLoading = "Loading Subtypes..";
            await UploadSubtypeAsync(projectId, dictionary, projects);
            CurrentlyLoading = "Loading Downcalls..";
            await UploadDowncallAsync(projectId, dictionary, projects);
            CurrentlyLoading = "Loading Dynamic..";
            await UploadDynamicAsync(projectId, dictionary, projects);
            CurrentlyLoading = "Loading Generic..";
            await UploadGenericAsync(projectId, dictionary, projects);
            CurrentlyLoading = null;
            IsLoading = false;
        }

        private string GetFilePath(string p)
        {
            return string.Format("{0}-{1}.csv", _basePath, p);
        }

        private static async Task UploadDynamicAsync(int projectId, Dictionary<string, int> dictionary, IList<ProjectViewModel> projects)
        {
            foreach (var p in projects)
            {
                if (p.FileDictionary["dynamic"].Exists)
                {
                    var dynamic = new DynamicInserter(projectId);
                    foreach (string line in File.ReadLines(p.GetFilePath("dynamic")).Skip(1))
                    {
                        string[] split = line.Split(';');
                        //fromType;toType;fromMethod;toMethod;calledFrom
                        dynamic.AddItem(int.Parse(split[0]), int.Parse(split[1]), int.Parse(split[2]), int.Parse(split[3]));
                    }
                    await dynamic.SaveAsync();
                }
                
            }
        }

        private void TryGetLineOfCodeData(out int linesOfCode, out int linesOfComment, out int linesOfBlank)
        {
            linesOfBlank = 0;
            linesOfComment = 0;
            linesOfCode = 0;
            if (_loc != null)
            {
                linesOfCode = _loc.Value;
            }
            else if (FileDictionary["loc"].Exists)
            {
                string line =
                    File.ReadAllLines(GetFilePath("loc")).Skip(1).FirstOrDefault();
                if (line == null) return;
                var split = line.Split(';');
                linesOfCode = int.Parse(split[0]);
                linesOfComment = int.Parse(split[1]);
                linesOfBlank = int.Parse(split[2]);
            }
        }

        private static async Task UploadDowncallAsync(int projectId, Dictionary<string, int> dictionary, IList<ProjectViewModel> projects)
        {
            foreach (var p in projects)
            {
                if (p.FileDictionary["downcall"].Exists)
                {
                    var downcallInserter = new DowncallInserter(projectId);
                    foreach (string line in File.ReadLines(p.GetFilePath("downcall")).Skip(1)
                        )
                    {
                        string[] split = line.Split(';');
                        //fromType;toType;fromMethod;toMethod;calledFrom
                        downcallInserter.AddItem(dictionary[split[0]], dictionary[split[1]], bool.Parse(split[2]), split[3], split[4],
                            split[5]);
                    }
                    await downcallInserter.SaveAsync();
                }
            }
        }

        private static async Task UploadSubtypeAsync(int projectId, Dictionary<string, int> dictionary, IList<ProjectViewModel> projects)
        {
            foreach (var p in projects)
            {
                var subtypeInsert = new SubtypeInserter(projectId);
                foreach (string line in File.ReadLines(p.GetFilePath("subtype")).Skip(1))
                {
                    string[] split = line.Split(';');
                    //direct?	source	from	to	from declaration
                    subtypeInsert.AddItem(dictionary[split[2]], dictionary[split[3]], bool.Parse(split[0]), split[1],
                        split[4]);
                }
                await subtypeInsert.SaveAsync();
            }
        }

        private static async Task UploadSuperAsync(int projectId, Dictionary<string, int> dictionary, IList<ProjectViewModel> projects)
        {
            foreach (var p in projects)
            {
                var superInsertion = new SuperInserter(projectId);
                foreach (string line in File.ReadLines(p.GetFilePath("super")).Skip(1))
                {
                    string[] split = line.Split(';');
                    superInsertion.AddItem(split[2], dictionary[split[0]], dictionary[split[1]]);
                }
                await superInsertion.SaveAsync();
            }
        }
        private static async Task UploadGenericAsync(int projectId, Dictionary<string, int> dictionary, IList<ProjectViewModel> projects)
        {
            foreach (var p in projects)
            {
                var superInsertion = new GenericInserter(projectId);
                foreach (string line in File.ReadLines(p.GetFilePath("generic")).Skip(1))
                {
                    string[] split = line.Split(';');
                    superInsertion.AddItem(dictionary[split[0]], dictionary[split[1]]);
                }
                await superInsertion.SaveAsync();
            }
        }

        private static async Task UploadExternalReuseAsync(int projectId, Dictionary<string, int> dictionary, IList<ProjectViewModel> projects)
        {
            foreach (var p in projects)
            {
                var reuseInserter = new ExternalReuseInserter(projectId);
                foreach (
                    string line in File.ReadLines(p.GetFilePath("external-reuse")).Skip(1))
                {
                    string[] split = line.Split(';');
                    reuseInserter.AddItem(bool.Parse(split[0]), split[4], TryGetArrayValue(split, 5), split[1],
                        dictionary[split[2]],
                        dictionary[split[3]]);
                }
                await reuseInserter.SaveAsync();
            }
        }

        private static async Task UploadInternalReuseAsync(int projectId, Dictionary<string, int> dictionary, IList<ProjectViewModel> projects)
        {
            foreach (var p in projects)
            {
                var reuseInserter = new InternalReuseInserter(projectId);
                foreach (
                    string line in File.ReadLines(p.GetFilePath("internal-reuse")).Skip(1))
                {
                    string[] split = line.Split(';');
                    reuseInserter.AddItem(bool.Parse(split[0]), split[4], TryGetArrayValue(split, 5), split[1],
                        dictionary[split[2]],
                        dictionary[split[3]]);
                }
                await reuseInserter.SaveAsync();
            }
        }

        private static string TryGetArrayValue(string[] split, int index)
        {
            if (split.Length <= index) return string.Empty;
            return split[index];
        }

        public void SetHasDataType(string name)
        {
            FileDictionary[name].Exists = true;
        }

        private int? _loc = null;
        internal void SetLinesOfCode(int loc)
        {
            _loc = loc;
        }

        internal void AddModule(ProjectViewModel projectViewModel)
        {
            _modules.Add(projectViewModel);
        }
    }
}