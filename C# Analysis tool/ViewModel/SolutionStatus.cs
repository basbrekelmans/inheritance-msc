using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSharpInheritanceAnalyzer.ViewModel
{
    public enum SolutionStatus
    {
        Queued,
        Running,
        LoadingParseTrees,
        BuildingTypeSystem,
        AnalyzingParseTrees,
        SavingOutput,
        CountingLinesOfCode,
        Completed
    }
}
