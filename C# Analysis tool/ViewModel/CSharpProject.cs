using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;
using CSharpInheritanceAnalyzer.Model.Sloc;
using ICSharpCode.NRefactory.CSharp;
using ICSharpCode.NRefactory.CSharp.Resolver;
using ICSharpCode.NRefactory.TypeSystem;
using Microsoft.Build.Evaluation;
using Microsoft.Build.Execution;
using Microsoft.Build.Framework;
using Microsoft.Build.Logging;

namespace CSharpInheritanceAnalyzer.ViewModel
{
    public class CSharpProject : ViewModelBaseEx
    {
        public const bool OnlyCountLines = false;

        private readonly CompilerSettings _compilerSettings = new CompilerSettings();
        private readonly List<CSharpFile> _files = new List<CSharpFile>();
        private readonly Guid _projectGuid;
        private readonly string _projectLocation;
        private readonly Solution _solution;
        private readonly string _title;
        private string _assemblyName;
        private ICompilation _compilation;
        private int _errors;

        private int _progressPercentage;
        private IProjectContent _projectContent;
        private int _warnings;


        public CSharpProject(Solution solution, string projectLocation, string title, Guid projectGuid)
        {
            _projectLocation = Path.GetFullPath(projectLocation);
            _solution = solution;
            _title = title;
            _projectGuid = projectGuid;
        }

        private bool _wasNotLoaded;

        public bool WasNotLoaded
        {
            get { return _wasNotLoaded; }
            set { Set(ref _wasNotLoaded, value); }
        }

        public int DynamicUsageCount { get; private set; }
        public int StaticUsageCount { get; private set; }

        public bool HasErrors
        {
            get { return _errors > 0; }
        }

        public bool HasWarnings
        {
            get { return _warnings > 0; }
        }

        public int ProgressPercentage
        {
            get { return _progressPercentage; }
            private set { Set(ref _progressPercentage, value); }
        }

        public string ProjectLocation
        {
            get { return _projectLocation; }
        }

        public Guid ProjectGuid
        {
            get { return _projectGuid; }
        }

        public string Title
        {
            get { return _title; }
        }

        public ICompilation Compilation
        {
            get { return _compilation; }
        }

        public IProjectContent ProjectContent
        {
            get { return _projectContent; }
        }

        public CompilerSettings CompilerSettings
        {
            get { return _compilerSettings; }
        }

        public int Warnings
        {
            get { return _warnings; }
            set { _warnings = value; }
        }

        public int Errors
        {
            get { return _errors; }
            set { _errors = value; }
        }

        public LineCountResult LinesOfCode { get; private set; }

        public void SetCompilation(ICompilation compilation)
        {
            _compilation = compilation;
        }

        public async Task LoadContentAsync()
        {
            _projectContent = await Task.Factory.StartNew(() =>
            {
                try
                {
// Use MSBuild to open the .csproj
                    var msbuildProject = new Project(_projectLocation);
                    // Figure out some compiler settings
                    _assemblyName = msbuildProject.GetPropertyValue("AssemblyName");
                    CompilerSettings.AllowUnsafeBlocks = GetBoolProperty(msbuildProject, "AllowUnsafeBlocks") ?? false;
                    CompilerSettings.CheckForOverflow = GetBoolProperty(msbuildProject, "CheckForOverflowUnderflow") ??
                                                        false;
                    string defineConstants = msbuildProject.GetPropertyValue("DefineConstants");
                    foreach (string symbol in defineConstants.Split(new[] {';'}, StringSplitOptions.RemoveEmptyEntries))
                        CompilerSettings.ConditionalSymbols.Add(symbol.Trim());


                    // Parse the C# code files
                    foreach (ProjectItem item in msbuildProject.GetItems("Compile"))
                    {
                        var file = new CSharpFile(this,
                            Path.Combine(msbuildProject.DirectoryPath, item.EvaluatedInclude));
                        _files.Add(file);
                    }

                    // Initialize the unresolved type system
                    IProjectContent projectContent = new CSharpProjectContent()
                        .SetAssemblyName(_assemblyName)
                        .SetProjectFileName(_projectLocation)
                        .SetCompilerSettings(CompilerSettings)
                        // Add parsed files to the type system
                        .AddOrUpdateFiles(_files.Where(f => f.FileExists).Select(f => f.UnresolvedTypeSystem));

                    if (OnlyCountLines) return projectContent;

                    // Add referenced assemblies:
                    foreach (string assemblyFile in ResolveAssemblyReferences(msbuildProject))
                    {
                        IUnresolvedAssembly assembly = _solution.LoadAssembly(assemblyFile);
                        projectContent = projectContent.AddAssemblyReferences(new IAssemblyReference[] {assembly});
                    }

                    // Add project references:
                    foreach (ProjectItem item in msbuildProject.GetItems("ProjectReference"))
                    {
                        string referencedFileName = Path.Combine(msbuildProject.DirectoryPath, item.EvaluatedInclude);
                        // Normalize the path; this is required to match the name with the referenced project's file name
                        referencedFileName = Path.GetFullPath(referencedFileName);
                        projectContent =
                            projectContent.AddAssemblyReferences(new IAssemblyReference[]
                            {new ProjectReference(referencedFileName)});
                    }
                    return projectContent;

                }
                catch (Exception)
                {
                    _wasNotLoaded = true;
                }
                return null;
                
            });
            RaisePropertyChanged(() => WasNotLoaded);
            RaisePropertyChanged(() => Errors);
            RaisePropertyChanged(() => HasErrors);
            RaisePropertyChanged(() => Warnings);
            RaisePropertyChanged(() => HasWarnings);
            ProgressPercentage = 40;
        }

        private IEnumerable<string> ResolveAssemblyReferences(Project project)
        {
            // Use MSBuild to figure out the full path of the referenced assemblies
            ProjectInstance projectInstance = project.CreateProjectInstance();
            projectInstance.SetProperty("BuildingProject", "false");
            project.SetProperty("DesignTimeBuild", "true");

            projectInstance.Build("ResolveAssemblyReferences", new[] {new ConsoleLogger(LoggerVerbosity.Minimal)});
            ICollection<ProjectItemInstance> items = projectInstance.GetItems("_ResolveAssemblyReferenceResolvedFiles");
            string baseDirectory = Path.GetDirectoryName(_projectLocation);
            // ReSharper disable once AssignNullToNotNullAttribute
            return items.Select(i => Path.Combine(baseDirectory, i.GetMetadataValue("Identity")));
        }

        private static bool? GetBoolProperty(Project p, string propertyName)
        {
            string val = p.GetPropertyValue(propertyName);
            bool result;
            if (bool.TryParse(val, out result))
                return result;
            return null;
        }

        public void AddToErrorCount(int count)
        {
            Errors += count;
        }

        public void AddToWarningCount(int count)
        {
            Warnings += count;
        }

        public async Task LoadCallsAsync()
        {

            if (OnlyCountLines) return;
            await Task.Factory.StartNew(() =>
            {
                if (_projectContent == null) return;
                var ownCodeAssemblyNames = new HashSet<string>(_solution.Projects.Select(p => p._assemblyName));
                foreach (var cSharpFile in _files.Where(f => f.FileExists))
                {
                    var resolver = cSharpFile.CreateResolver();
                    var callVisitor = new CallVisitor(resolver, _solution.Nodes, _solution.Edges, ownCodeAssemblyNames);
                    cSharpFile.AcceptAstVisitor(callVisitor);
                    this.DynamicUsageCount += callVisitor.DynamicUsage;
                    this.StaticUsageCount += callVisitor.StaticUsage;
                }

            });
            ProgressPercentage = 100;
        }

        public async Task LoadMethodsAsync()
        {
            if (OnlyCountLines) return;
            await Task.Factory.StartNew(() =>
            {
                if (_projectContent == null) return;
                var ownCodeAssemblyNames = new HashSet<string>(_solution.Projects.Select(p => p._assemblyName));
                foreach (var cSharpFile in _files.Where(f => f.FileExists))
                {
                    var resolver = cSharpFile.CreateResolver();
                    var methodDeclarationVisitor = new MethodDeclarationVisitor(resolver, _solution.Nodes,
                        _solution.Edges, ownCodeAssemblyNames);
                    cSharpFile.AcceptAstVisitor(methodDeclarationVisitor);
                    this.DynamicUsageCount += methodDeclarationVisitor.DynamicUsage;
                    this.StaticUsageCount += methodDeclarationVisitor.StaticUsage;
                }

            });
            ProgressPercentage = 60;
        }

        public async Task CountLinesAsync()
        {
            await Task.Run(() =>
            {
                this.LinesOfCode = _files.Where(f => f.FileExists).Aggregate(new LineCountResult(0, 0, 0), (current, cSharpFile) => current + LineCounter.CountLines(File.ReadAllLines(cSharpFile.FilePath)));
            });
            this.ProgressPercentage = OnlyCountLines ? 100 : 45;
            RaisePropertyChanged(() => LinesOfCode);
        }

        public async Task LoadTypesAsync()
        {
            if (OnlyCountLines) return;
            await Task.Factory.StartNew(() =>
            {
                if (_projectContent == null) return;
                var ownCodeAssemblyNames = new HashSet<string>(_solution.Projects.Select(p => p._assemblyName));
                foreach (var cSharpFile in _files.Where(f => f.FileExists))
                {
                    _compilation = _projectContent.CreateCompilation(_solution.Snapshot);
                    var resolver = cSharpFile.CreateResolver();
                    var typeBuilder = new TypeSystemBuilder(resolver, _solution.Nodes, _solution.Edges, ownCodeAssemblyNames);
                    cSharpFile.AcceptAstVisitor(typeBuilder);
                }

            });
            ProgressPercentage = 50;
        }
        
        public void Clear()
        {
            _files.Clear();
            _projectContent = null;
        }
    }
}