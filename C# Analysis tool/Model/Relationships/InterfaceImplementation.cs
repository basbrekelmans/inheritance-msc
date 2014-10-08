using CSharpInheritanceAnalyzer.Model.Types;

namespace CSharpInheritanceAnalyzer.Model.Relationships
{
    public class InterfaceImplementation : TypeToInterface<Class> 
    {
        public InterfaceImplementation(Class derivedType, Interface baseType) : base(derivedType, baseType)
        {

        }

        public override string InheritanceTypeName
        {
            get { return "CI"; }
        }
    }
}
