using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSharpInheritanceAnalyzer.Model.Relationships
{
    public enum SubtypeKind
    {
        Assignment,
        VariableInitializer,
        Cast,
        Return,
        Parameter,
        ThisChangingType,
        ContravariantTypeArgument,
        CovariantTypeArgument,
        Foreach

    }
}
