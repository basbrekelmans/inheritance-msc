using System;
using CSharpInheritanceAnalyzer.Model.Relationships;

namespace CSharpInheritanceAnalyzer.Model.Types
{
    public class Class : CSharpType
    {
        public Class(bool isOwnCode, string fullyQualifiedName, bool isConstants, int typeParameterCount, bool isMarker)
            : base(isOwnCode, fullyQualifiedName, isConstants, typeParameterCount, isMarker)
        {
        }

        public override IInheritanceRelationship AddBaseType(CSharpType baseTypeDefinition)
        {
            return baseTypeDefinition.AddDerivedClass(this);
        }

        protected internal override IInheritanceRelationship AddDerivedClass(Class derived)
        {
            var relationship = new ClassToClass(derived, this);
            derived.BaseTypeRelationships.Add(relationship);
            DerivedTypeRelationships.Add(relationship);
            return relationship;
        }

        protected internal override IInheritanceRelationship AddDerivedInterface(Interface derived)
        {
            throw new InvalidOperationException("An interface cannot derive from a class.");
        }

        public override string GetLocString()
        {
            return string.Format(@"cs+class://{0}", string.Join("/", FullyQualifiedName.Split('.')));
        }
    }
}