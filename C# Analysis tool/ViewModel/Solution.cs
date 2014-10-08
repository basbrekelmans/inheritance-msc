using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using CSharpInheritanceAnalyzer.Model.Relationships;
using CSharpInheritanceAnalyzer.Model.Sloc;
using CSharpInheritanceAnalyzer.Model.Types;
using ICSharpCode.NRefactory.TypeSystem;

namespace CSharpInheritanceAnalyzer.ViewModel
{
    public class Solution : ViewModelBaseEx
    {
        private readonly string _filePath;

        private static readonly Regex ProjectLinePattern =
            new Regex(
                "Project\\(\"(?<TypeGuid>.*)\"\\)\\s+=\\s+\"(?<Title>.*)\",\\s*\"(?<Location>.*)\",\\s*\"(?<Guid>.*)\"",
                RegexOptions.Compiled);

        private readonly ConcurrentDictionary<string, IUnresolvedAssembly> _assemblyCache =
            new ConcurrentDictionary<string, IUnresolvedAssembly>();

        private readonly string _fileName;
        private readonly IList<CSharpProject> _projects;
        private readonly string _solutionDirectory;
        private SolutionStatus _status;
        private DefaultSolutionSnapshot _snapshot;

        public bool IsBuilding { get; set; }

        private static readonly Regex FileNameIncludingDescription = new Regex(@"([\w\.]+)\s*=\s*(.+)");

        public Solution(string filePath)
        {
            if (IsInDesignMode)
            {
                _fileName = filePath;
                _projects = new List<CSharpProject>
                {
                    new CSharpProject(this, "ABC", "ProjectA", Guid.Empty),
                    new CSharpProject(this, "ABC", "ProjectA.B.C.D", Guid.Empty),
                    new CSharpProject(this, "ABC", "Project.LongNameABC", Guid.Empty),
                    new CSharpProject(this, "ABC", "Project V", Guid.Empty),
                    new CSharpProject(this, "ABC", "Project W", Guid.Empty),
                    new CSharpProject(this, "ABC", "Project X", Guid.Empty),
                    new CSharpProject(this, "ABC", "Project Y", Guid.Empty),
                    new CSharpProject(this, "ABC", "Project Z", Guid.Empty),
                };
            }
            else
            {
                var match = FileNameIncludingDescription.Match(filePath);
                if (match.Success)
                {
                    _filePath = match.Groups[2].Value;
                    _fileName = match.Groups[1].Value + ".sln";
                }
                else
                {
                    _filePath = filePath;
                    _fileName = Path.GetFileName(_filePath);
                }
                _status = SolutionStatus.Queued;
                _solutionDirectory = Path.GetDirectoryName(_filePath);
                _projects = LoadProjectFiles(_filePath);
                Edges = new List<IInheritanceRelationship>(10000);
                Nodes = new Dictionary<string, CSharpType>(10000);
            }
        }

        public int ProgressPercentage
        {
            get { return (int) Math.Round(_projects.Average(p => p.ProgressPercentage)); }
        }

        public SolutionStatus Status
        {
            get { return _status; }
            set { Set(ref _status, value); }
        }

        public string FileName
        {
            get { return _fileName; }
        }

        public IList<CSharpProject> Projects
        {
            get { return _projects; }
        }

        public async Task AnalyzeAsync(CancellationToken cancellationToken)
        {
            IsBuilding = true;
            Status = SolutionStatus.LoadingParseTrees;

            foreach (var project in Projects)
            {
                if (cancellationToken.IsCancellationRequested) return;
                await project.LoadContentAsync();
            }
            if (cancellationToken.IsCancellationRequested) return;
            await Task.WhenAll(from pr in _projects
                where pr.ProjectContent != null
                select pr.CountLinesAsync());
            if (cancellationToken.IsCancellationRequested) return;
            Status = SolutionStatus.CountingLinesOfCode;

            this.LinesOfCode = _projects.Where(pr => pr.ProjectContent != null).Aggregate(new LineCountResult(0,0,0), (c, p) => c + p.LinesOfCode);


            this._snapshot = new DefaultSolutionSnapshot(_projects.Where(p => p.ProjectContent != null).Select(p => p.ProjectContent));
            Status = SolutionStatus.BuildingTypeSystem;
            IsBuilding = false;
           
            foreach (var project in Projects)
            {
                if (cancellationToken.IsCancellationRequested) return;
                await project.LoadTypesAsync();
            }

            foreach (var cSharpProject in Projects)
            {
                if (cancellationToken.IsCancellationRequested) return;
                await cSharpProject.LoadMethodsAsync();
            }

            Status = SolutionStatus.AnalyzingParseTrees;
            foreach (var cSharpProject in Projects)
            {
                if (cancellationToken.IsCancellationRequested) return;
                await cSharpProject.LoadCallsAsync();
            }

            Status = SolutionStatus.SavingOutput;
            if (cancellationToken.IsCancellationRequested) return;
            await Task.Run(() =>
            {
                using (var writer = OpenTruncate(Path.GetFileNameWithoutExtension(FileName) + "-loc.csv"))
                {
                    writer.WriteCsvLine("LinesOfCode", "LinesOfComment", "BlankLines");
                    writer.WriteCsvLine(LinesOfCode.CodeCount, LinesOfCode.CommentCount, LinesOfCode.BlankCount);
                }
            });
            if (cancellationToken.IsCancellationRequested) return;
            await Task.Run(() =>
            {
                using (var writer = OpenTruncate(Path.GetFileNameWithoutExtension(FileName) + "-dynamic.csv"))
                {
                    writer.WriteCsvLine("Static Occurrances", "Dynamic Occurrences");
                    writer.WriteCsvLine(Projects.Sum(p => p.StaticUsageCount), Projects.Sum(p => p.DynamicUsageCount));
                }
            });
            if (cancellationToken.IsCancellationRequested) return;
            await Task.Run(() =>
            {
                using (var writer = OpenTruncate(Path.GetFileNameWithoutExtension(FileName) + "-types.csv"))
                {
                    writer.WriteCsvLine("TypeName;SystemType");
                    foreach (var cSharpType in Nodes.Values)
                    {
                        writer.WriteCsvLine(cSharpType.GetLocString(), cSharpType.IsOwnCode);
                    }
                }
            });
            if (cancellationToken.IsCancellationRequested) return;
            await Task.Run(() =>
            {
                using (var writer = OpenTruncate(Path.GetFileNameWithoutExtension(FileName) + "-inheritance.csv"))
                {
                    writer.WriteLine("type;from;to;direct;marker;constants;systemType");
                    foreach (var inheritanceRelationship in Edges)
                    {
                        var derivedName = inheritanceRelationship.DerivedType.GetLocString();
                        var type = inheritanceRelationship.InheritanceTypeName;
                        var baseName = inheritanceRelationship.BaseType.GetLocString();
                        writer.WriteCsvLine(type, derivedName, baseName, true, inheritanceRelationship.Marker, inheritanceRelationship.BaseType.IsConstants,
                            inheritanceRelationship.BaseType.IsOwnCode);
                    }

                }
                if (cancellationToken.IsCancellationRequested) return;
                using (var writer = OpenTruncate(Path.GetFileNameWithoutExtension(FileName) + "-internal-reuse.csv"))
                {
                    writer.WriteLine("direct?;source;from;to;from declaration;to declaration");
                    foreach (var inheritanceRelationship in Edges)
                    {
                        var derivedName = inheritanceRelationship.DerivedType.GetLocString();
                        var baseName = inheritanceRelationship.BaseType.GetLocString();
                        foreach (var reuse in inheritanceRelationship.InternalReuse)
                        {
                            writer.WriteCsvLine(reuse.IsDirect, reuse.Type, derivedName, baseName, reuse.Name, reuse.From);
                        }
                    }
                }
                if (cancellationToken.IsCancellationRequested) return;
                using (var writer = OpenTruncate(Path.GetFileNameWithoutExtension(FileName) + "-external-reuse.csv"))
                {
                    writer.WriteLine("direct?;source;from;to;from declaration;to declaration");
                    foreach (var inheritanceRelationship in Edges)
                    {
                        var derivedName = inheritanceRelationship.DerivedType.GetLocString();
                        var baseName = inheritanceRelationship.BaseType.GetLocString();
                        foreach (var reuse in inheritanceRelationship.ExternalReuse)
                        {
                            writer.WriteCsvLine(reuse.IsDirect, reuse.Type, derivedName, baseName, reuse.Name, reuse.From);
                        }
                    }
                }

                if (cancellationToken.IsCancellationRequested) return;
                using (var writer = OpenTruncate(Path.GetFileNameWithoutExtension(FileName) + "-subtype.csv"))
                {
                    writer.WriteLine("direct?;source;from;to;from declaration");
                    foreach (var inheritanceRelationship in Edges)
                    {
                        var derivedName = inheritanceRelationship.DerivedType.GetLocString();
                        var baseName = inheritanceRelationship.BaseType.GetLocString();
                        foreach (var subtype in inheritanceRelationship.Subtypes)
                        {
                            writer.WriteCsvLine(subtype.IsDirect, subtype.Kind, derivedName, baseName, subtype.FromReference);
                        }
                    }
                }
                if (cancellationToken.IsCancellationRequested) return;
                using (var writer = OpenTruncate(Path.GetFileNameWithoutExtension(FileName) + "-downcall.csv"))
                {
                    writer.WriteLine("fromType;toType;fromMethod;toMethod;calledFrom");
                    foreach (var inheritanceRelationship in Edges)
                    {
                        var derivedName = inheritanceRelationship.DerivedType.GetLocString();
                        var baseName = inheritanceRelationship.BaseType.GetLocString();
                        foreach (var downcall in inheritanceRelationship.Downcalls)
                        {
                            writer.WriteCsvLine(derivedName, baseName, downcall.Method, downcall.Method, downcall.FromReference);
                        }
                    }
                }
                if (cancellationToken.IsCancellationRequested) return;
                using (var writer = OpenTruncate(Path.GetFileNameWithoutExtension(FileName) + "-super.csv"))
                {
                    writer.WriteLine("From;To;Source");
                    foreach (var inheritanceRelationship in Edges.Where(e => e.Super))
                    {
                        var derivedName = inheritanceRelationship.DerivedType.GetLocString();
                        var baseName = inheritanceRelationship.BaseType.GetLocString();
                        writer.WriteCsvLine(derivedName, baseName, "(not implemented)");
                    }
                }
                if (cancellationToken.IsCancellationRequested) return;
                using (var writer = OpenTruncate(Path.GetFileNameWithoutExtension(FileName) + "-generic.csv"))
                {
                    writer.WriteLine("From;To;");
                    foreach (var inheritanceRelationship in Edges.Where(e => e.Generic))
                    {
                        var derivedName = inheritanceRelationship.DerivedType.GetLocString();
                        var baseName = inheritanceRelationship.BaseType.GetLocString();
                        writer.WriteCsvLine(derivedName, baseName);
                    }
                }
            });
            Status = SolutionStatus.Completed;
            //enable GC to prevent OutOfMemoryExceptions
            Nodes = null;
            Edges = null;
            _snapshot = null;
            _assemblyCache.Clear();
            foreach (var cSharpProject in _projects)
            {
                cSharpProject.Clear();
            }
        }

        private LineCountResult _linesOfCode;

        public LineCountResult LinesOfCode
        {
            get { return _linesOfCode; }
            set { Set(ref _linesOfCode, value); }
        }


        private static StreamWriter OpenTruncate(string path)
        {
            var stream = new FileStream(Path.Combine(@"C:\InheritanceTest\Output\CSharp_QNH ", path), FileMode.Create);
            return new StreamWriter(stream);
        }


        private static void SetOverrides(CSharpType declaringType, Method method)
        {
            foreach (var inheritanceRelationship in declaringType.DerivedTypeRelationships)
            {
                var derivedType = inheritanceRelationship.DerivedType;

                foreach (var declaredMethod in derivedType.DeclaredMethods)
                {
                    if (declaredMethod.SignatureEquals(method))
                    {
                        method.DeclaringType.OverrideOccurrences.Add(declaredMethod);
                    }
                }
                SetOverrides(derivedType, method);
            }
        }

        private static void AddOverrides(CSharpType declaringType, Method method)
        {
            foreach (var inheritanceRelationship in declaringType.BaseTypeRelationships)
            {
                var baseType = inheritanceRelationship.BaseType;

                foreach (var declaredMethod in baseType.DeclaredMethods)
                {
                    if (declaredMethod.SignatureEquals(method))
                    {
                        baseType.OverrideOccurrences.Add(method);
                    }
                }
                AddOverrides(baseType, method);
            }
        }

        private IList<CSharpProject> LoadProjectFiles(string solutionFile)
        {
            var projectList = new List<CSharpProject>();

            foreach (string line in File.ReadLines(solutionFile))
            {
                Match match = ProjectLinePattern.Match(line);
                if (match.Success)
                {
                    string typeGuid = match.Groups["TypeGuid"].Value.ToUpperInvariant();
                    switch (typeGuid)
                    {
                        case "{2150E333-8FDC-42A3-9474-1A3956D46DE8}": // Solution Folder
                            // ignore folders
                            break;
                        case "{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}": // C# project
                            string title = match.Groups["Title"].Value;
                            string location = match.Groups["Location"].Value;
                            Guid projectGuid = Guid.Parse(match.Groups["Guid"].Value);
                            var project = new CSharpProject(this, Path.Combine(_solutionDirectory, location),
                                title, projectGuid);
                            project.PropertyChanged += OnProjectPropertyChanged;
                            projectList.Add(project);
                            break;
                    }
                }
            }
            return projectList;
        }

        private void OnProjectPropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == "ProgressPercentage")
                RaisePropertyChanged("ProgressPercentage");
        }

        public List<IInheritanceRelationship> Edges { get; private set; }
        public Dictionary<string, CSharpType> Nodes { get; private set; }

        public DefaultSolutionSnapshot Snapshot
        {
            get { return _snapshot; }
        }

        public string FilePath
        {
            get { return _filePath; }
        }

        public IUnresolvedAssembly LoadAssembly(string assemblyFile)
        {
            return _assemblyCache.GetOrAdd(assemblyFile, file => new CecilLoader().LoadAssemblyFile(file));
        }
    }

    public static class TextWriterExtensions
    {
        public static void WriteCsvLine(this TextWriter writer, params object[] values)
        {
            writer.WriteLine(string.Join(";", values));
        }
    }
}