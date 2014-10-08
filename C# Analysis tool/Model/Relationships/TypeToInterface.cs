using System.Linq;
using CSharpInheritanceAnalyzer.Model.Types;

namespace CSharpInheritanceAnalyzer.Model.Relationships
{
    public abstract class TypeToInterface<TDerived>
        : InheritanceRelationship<TDerived, Interface>
        where TDerived : CSharpType
    {
        protected TypeToInterface(TDerived derivedType, Interface baseType) : base(derivedType, baseType)
        {
        }

        public override bool Marker
        {
            get
            {
                return BaseType.IsMarker
                       && BaseType.BaseTypeRelationships.All(r => r.BaseType.IsObject || r.Marker);
            }
        }
    }
}