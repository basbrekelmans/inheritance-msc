using System.Collections;
using System.Collections.Generic;
using System.Linq;
using CSharpInheritanceAnalyzer.Model.Relationships;

namespace CSharpInheritanceAnalyzer.Model.Types
{
    public abstract class CSharpType
    {
        private readonly bool _isOwnCode;
        private readonly string _fullyQualifiedName;
        private readonly bool _isConstants;
        private readonly int _typeParameterCount;
        public bool HasBeenCastFromObject { get; set; }
        public bool HasSubtypeToObject { get; set; }

        private static readonly CSharpType _unknownType = new UnknownType();
        private static readonly CSharpType _void = new VoidType();
        private static readonly CSharpType _dynamic = new DynamicType();
        private readonly bool _isMarker;

        protected CSharpType(bool isOwnCode, string fullyQualifiedName, bool isConstants, int typeParameterCount, bool isMarker)
        {
            if (fullyQualifiedName == "?")
            {
                
            }
            _isOwnCode = isOwnCode;
            _fullyQualifiedName = fullyQualifiedName;
            _isConstants = isConstants;
            _typeParameterCount = typeParameterCount;
            _isMarker = isMarker;
            DeclaredMethods = new HashSet<Method>();
            CalledMethods = new HashSet<Method>();
            BaseTypeRelationships = new List<IInheritanceRelationship>();
            OverrideOccurrences = new HashSet<Method>();
            DerivedTypeRelationships = new List<IInheritanceRelationship>();
        }

        public override string ToString()
        {
            return _fullyQualifiedName + (IsOwnCode ? string.Empty : " (external)");
        }

        public IList<IInheritanceRelationship> BaseTypeRelationships { get; private set; }
        public IList<IInheritanceRelationship> DerivedTypeRelationships { get; private set; }

        public static CSharpType Unknown
        {
            get
            {
                return _unknownType;
            }
        }

        public ISet<Method> DeclaredMethods { get; private set; }
        public ISet<Method> CalledMethods { get; private set; }
        public ISet<Method> OverrideOccurrences { get; private set; }
        public bool IsOwnCode
        {
            get { return _isOwnCode; }
        }

        public string FullyQualifiedName
        {
            get { return _fullyQualifiedName; }
        }

        public bool IsObject
        {
            get { return _fullyQualifiedName == "System.Object"; }
        }

        public string Name
        {
            get { return _fullyQualifiedName.Substring(FullyQualifiedName.LastIndexOf(".", System.StringComparison.Ordinal) + 1); }
        }

        public static CSharpType Void
        {
            get { return _void; }
        }
        public static CSharpType Dynamic
        {
            get { return _dynamic; }
        }

        public int TypeParameterCount
        {
            get { return _typeParameterCount; }
        }

        public abstract IInheritanceRelationship AddBaseType(CSharpType baseTypeDefinition);

        protected internal abstract IInheritanceRelationship AddDerivedClass(Class derived);

        protected internal abstract IInheritanceRelationship AddDerivedInterface(Interface derived);

        public abstract string GetLocString();

        public bool IsParentOf(CSharpType targetType)
        {
            return DerivedTypeRelationships.Any(r => r.DerivedType == targetType || r.DerivedType.IsParentOf(targetType));
        }

        public bool IsChildOf(CSharpType targetType)
        {
            return BaseTypeRelationships.Any(r => r.BaseType == targetType || r.BaseType.IsChildOf(targetType));
        }
        

        public bool IsDirectChildOf(CSharpType methodDeclaringType)
        {
            return BaseTypeRelationships.Any(r => r.BaseType == methodDeclaringType);
        }
        public IInheritanceRelationship GetImmediateParent(CSharpType targetType)
        {
            return BaseTypeRelationships.First(r => r.BaseType == targetType || r.BaseType.IsChildOf(targetType));
        }

        public IEnumerable<CSharpType> AllDerivedTypes()
        {
            return DerivedTypeRelationships
                .SelectMany(r => r.DerivedType.AllDerivedTypes()
                    .Concat(r.DerivedType));

        }

        public bool IsConstants { get { return _isConstants; } }

        public bool IsMarker { get { return _isMarker; } }


        internal IEnumerable<IInheritanceRelationship> GetPathTo(CSharpType parent)
        {
            IInheritanceRelationship current = GetImmediateParent(parent);
            while(true)
            {
                yield return current;
                if (current.BaseType.IsChildOf(parent))
                    current = current.BaseType.GetImmediateParent(parent);
                else break;
            }
        }
    }

    internal class DynamicType : Interface
    {
        public DynamicType()
            : base(false, "Dynamic", true, 0, true)
        {
            
        }
    }

    internal class VoidType : Interface
    {
        public VoidType()
            : base(false, "System.Void", true, 0, true)
        {
        }
    }
}