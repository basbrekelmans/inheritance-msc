using System;
using System.Diagnostics;
using System.Linq;

namespace CSharpInheritanceAnalyzer.Model.Types
{
    public class  Method : IEquatable<Method>
    {
        public bool Equals(Method other)
        {
            if (ReferenceEquals(null, other)) return false;
            if (ReferenceEquals(this, other)) return true;
            return SignatureEquals(other);

        }

        public override int GetHashCode()
        {
            unchecked
            {
                int hashCode = _methodName.GetHashCode();
                hashCode = (hashCode*397) ^ _returnType.GetHashCode();
                return Parameters.Aggregate(hashCode, (current, cSharpType) => (current*397) ^ cSharpType.GetHashCode());
            }
        }

        public static bool operator ==(Method left, Method right)
        {
            return Equals(left, right);
        }

        public static bool operator !=(Method left, Method right)
        {
            return !Equals(left, right);
        }

        private readonly CSharpType _declaringType;
        private readonly string _methodName;
        private readonly CSharpType _returnType;
        private readonly CSharpType[] _parameters;

        public Method(CSharpType declaringType, string methodName, CSharpType returnType, CSharpType[] parameters)
        {
            _declaringType = declaringType;
            _methodName = methodName;
            _returnType = returnType;
            _parameters = parameters;
        }

        private static readonly CSharpType[] EmptyParamList = new CSharpType[0];

        public Method(CSharpType declaringType, string methodName, CSharpType returnType)
            : this(declaringType, methodName, returnType, EmptyParamList)
        {
        }

        public CSharpType DeclaringType
        {
            get { return _declaringType; }
        }

        public string MethodName
        {
            get { return _methodName; }
        }

        public CSharpType ReturnType
        {
            get { return _returnType; }
        }

        public CSharpType[] Parameters
        {
            get { return _parameters; }
        }


        public override bool Equals(object obj)
        {
            if (ReferenceEquals(null, obj)) return false;
            if (ReferenceEquals(this, obj)) return true;
            if (obj.GetType() != this.GetType()) return false;
            return Equals((Method) obj);
        }

        public bool SignatureEquals(Method other)
        {
            bool signatureEquals = string.Equals(_methodName, other._methodName) &&
                            _returnType.Equals(other._returnType);
            if (signatureEquals) return true;
            if (other.Parameters.Length != Parameters.Length) return false;

            return Parameters.SequenceEqual(other.Parameters);
        }

        public override string ToString()
        {
            return string.Format("{0} {1}({2})", ReturnType.Name, MethodName,
                string.Join(", ", Parameters.Select(p => p.Name)));
        }
    }
}