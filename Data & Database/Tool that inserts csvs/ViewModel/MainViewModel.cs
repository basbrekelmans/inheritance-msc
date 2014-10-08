using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using GalaSoft.MvvmLight;

namespace InheritanceInsertion.ViewModel
{
    /// <summary>
    /// This class contains properties that the main View can data bind to.
    /// <para>
    /// Use the <strong>mvvminpc</strong> snippet to add bindable properties to this ViewModel.
    /// </para>
    /// <para>
    /// You can also use Blend to data bind with the tool's support.
    /// </para>
    /// <para>
    /// See http://www.galasoft.ch/mvvm
    /// </para>
    /// </summary>
    public class MainViewModel : ViewModelBase
    {
        private static readonly Regex ModuleMatcher =
            new Regex(@"(.{2,})_(.*)");

        private static readonly Regex FileMatcher =
            new Regex(@"([\w\-\d\.\s]+)-(inheritance|downcall|external-reuse|internal-reuse|subtype|super|generic|types|loc|dynamic).csv",
                RegexOptions.Compiled);

        /// <summary>
        /// Initializes a new instance of the MainViewModel class.
        /// </summary>
        public MainViewModel()
        {
            var projects = new Dictionary<string, ProjectViewModel>();
            Dictionary<string, int> linesOfCodeJava = (from l in
                File.ReadLines(@"C:\InheritanceTest\JavaOssLoc.csv").Skip(1)
                select l.Split(';')).ToDictionary(s => s[0], s => int.Parse(s[1]));

            ISet<string> existingProjects = ProjectInfo.ExistingProjectNames();

           // GetProjects(@"C:\InheritanceTest\CSharp-InheritanceFInal", "C#", projects, "Open Source", linesOfCodeJava, existingProjects);
            GetProjects(@"C:\InheritanceTest\Java Inheritance", "Java", projects, "Open Source", linesOfCodeJava, existingProjects);
            // GetProjects("C:\\InheritanceTest\\Output", "Java", projects);
            //GetProjects("C:\\InheritanceTest\\Megamek", "Java", projects, "Open Source", linesOfCodeJava);
            //GetProjects("C:\\InheritanceTest\\CSharp", "C#", projects, "Open Source", linesOfCodeJava);
            //GetProjects("C:\\InheritanceTest\\CSharp_QNH", "C#", projects, "Industry", linesOfCodeJava);
           // GetProjects(@"C:\Users\Bastiaan.Brekelmans\Documents\Visual Studio 2013\Projects\CSharpInheritanceAnalyzer\bin\Release", "C#", projects);
            this.Projects = projects.Values.ToList();
        }
        private static void GetProjects(string path, string language, Dictionary<string, ProjectViewModel> projects, string sourceType, Dictionary<string, int> javaLoc, ISet<string> existingProjects)
        {

            foreach (var fileName in Directory.GetFiles(path, "*.csv"))
            {
                var match = FileMatcher.Match(fileName);
                if (match.Success)
                {
                    string projectName = match.Groups[1].Value;
                    string dataType = match.Groups[2].Value;
                    string moduleName = null;

                    var module = ModuleMatcher.Match(projectName);
                    if (module.Success)
                    {
                        projectName = module.Groups[1].Value;
                        moduleName = module.Groups[2].Value;
                    }
                    else if (projectName.StartsWith("org.springframework"))
                    {
                        moduleName = projectName.Substring("org.springframework".Length);
                        projectName = "org.springframework";
                    }
                    string basePath = Path.Combine(Path.GetDirectoryName(fileName), match.Groups[1].Value);
                    ProjectViewModel project;
                    if (!projects.TryGetValue(projectName, out project))
                    {
                        project = new ProjectViewModel(basePath, projectName, language,
                            sourceType, moduleName);
                        projects.Add(projectName, project);
                    }
                    else if (project.Modules.All(m => m.ModuleName != moduleName))
                    {
                        var m = new ProjectViewModel(basePath, projectName,
                            language, sourceType, moduleName);
                        project.AddModule(m);
                        project = m;
                    }

                    if (existingProjects.Contains(project.Name))
                    {
                        project.Exists = true;
                    }
                    
                    int loc;
                    if (javaLoc.TryGetValue(match.Groups[1].Value, out loc))
                    {
                        project.SetLinesOfCode(loc);
                    }

                    project.SetHasDataType(dataType);
                }
            }
        }

        private List<ProjectViewModel> _projects;

        public List<ProjectViewModel> Projects
        {
            get { return _projects; }
            set { Set("Projects", ref _projects, value); }
        }
        
    }
}