using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using CSharpInheritanceAnalyzer.Model.Relationships;
using CSharpInheritanceAnalyzer.Model.Types;
using ICSharpCode.NRefactory.CSharp;
using ICSharpCode.NRefactory.CSharp.Resolver;
using ICSharpCode.NRefactory.TypeSystem;

namespace CSharpInheritanceAnalyzer.ViewModel
{
    public abstract class VisitorBase : DepthFirstAstVisitor
    {
        protected readonly List<IInheritanceRelationship> Edges;
        protected readonly HashSet<string> OwnCodeAssemblyNames;
        protected readonly CSharpAstResolver Resolver;
        protected readonly IDictionary<string, CSharpType> Types;

        public int DynamicUsage, StaticUsage;

        protected VisitorBase(CSharpAstResolver resolver, IDictionary<string, CSharpType> types,
            List<IInheritanceRelationship> edges, HashSet<string> ownCodeAssemblyNames)
        {
            Resolver = resolver;
            Types = types;
            Edges = edges;
            OwnCodeAssemblyNames = ownCodeAssemblyNames;
        }

        protected CSharpType GetTypeOrCreateExternal(IType type)
        {

            CSharpType result;
            if (!Types.TryGetValue(type.GetFullName(), out result))
            {
                var members = type.GetMembers().Where(m => m.DeclaringType.FullName != "System.Object").ToList();
                bool constants = members.Count > 0 && members.All(member => member.SymbolKind == SymbolKind.Field
                                                    && member.IsStatic
                                                    && ((IField)member).IsReadOnly);

                bool marker = members.Count == 0;
                string fullName = type.GetFullName();
                if (type.Kind == TypeKind.Interface)
                {
                    result = new Interface(false, fullName, constants, type.TypeParameterCount, marker);
                }
                else if (type.Kind == TypeKind.Class || type.Kind == TypeKind.Struct)
                {
                    result = new Class(false, fullName, constants, type.TypeParameterCount, marker);
                }
                else if (type.Kind == TypeKind.Void)
                {
                    result = CSharpType.Void;
                    goto end;
                }
                else if (type.Kind == TypeKind.Dynamic)
                {
                    result = CSharpType.Dynamic;
                    goto end;
                }
                else
                {
                    result = CSharpType.Unknown;
                    goto end;
                }
                Types.Add(fullName, result);
                result.DeclaredMethods.UnionWith(type.GetMembers().OfType<IParameterizedMember>().Select(CreateMethod));
                foreach (var baseType in type.DirectBaseTypes)
                {
                    var definition = GetTypeOrCreateExternal(baseType);
                    if (type.Kind == TypeKind.Interface && definition.IsObject) continue;
                    
                    result.AddBaseType(definition);
                }
            }
            end:
            if (result == CSharpType.Dynamic)
            {
                DynamicUsage++;
            }
            else
            {
                StaticUsage++;
            }
            return result;
        }


        protected Method CreateMethod(IParameterizedMember member)
        {
            var declaringType = GetTypeOrCreateExternal(member.DeclaringType);
            var returnType = GetTypeOrCreateExternal(member.ReturnType);

            var parameters = member.Parameters.Select(p => GetTypeOrCreateExternal(p.Type)).ToArray();

            return new Method(declaringType, member.Name, returnType, parameters);
        }
    }
}