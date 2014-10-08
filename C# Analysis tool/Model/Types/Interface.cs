using CSharpInheritanceAnalyzer.Model.Relationships;

namespace CSharpInheritanceAnalyzer.Model.Types
{
    public class Interface : CSharpType
    {
        public Interface(bool isOwnCode, string fullyQualifiedName, bool isConstants, int typeParameterCount, bool isMarker)
            : base(isOwnCode, fullyQualifiedName, isConstants, typeParameterCount, isMarker)
        {
        }

        public override IInheritanceRelationship AddBaseType(CSharpType baseTypeDefinition)
        {
            return baseTypeDefinition.AddDerivedInterface(this);
        }

        protected internal override IInheritanceRelationship AddDerivedClass(Class derived)
        {
            var relationship = new InterfaceImplementation(derived, this);
            derived.BaseTypeRelationships.Add(relationship);
            this.DerivedTypeRelationships.Add(relationship);
            return relationship;
        }

        protected internal override IInheritanceRelationship AddDerivedInterface(Interface derived)
        {
            var relationship = new InterfaceToInterface(derived, this);
            derived.BaseTypeRelationships.Add(relationship);
            this.DerivedTypeRelationships.Add(relationship);
            return relationship;
        }

        public override string GetLocString()
        {
            return string.Format(@"cs+interface://{0}", string.Join("/", FullyQualifiedName.Split('.')));
        }
    }
}