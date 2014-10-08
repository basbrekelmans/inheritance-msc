using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CSharpInheritanceAnalyzer.Model.Types;

namespace CSharpInheritanceAnalyzer.Model.Relationships
{
    public interface IInheritanceRelationship
    {
        CSharpType BaseType { get; }
        CSharpType DerivedType { get; }
        IList<Reuse> InternalReuse { get; }
        IList<Reuse> ExternalReuse { get; }
        IList<Downcall> Downcalls { get; }
        IList<Subtype> Subtypes { get; }
        bool Marker { get; }
        bool Constants { get; }

        bool Generic { get; }
        string InheritanceTypeName { get; }
        bool Super { get; }
    }
}
