using System.Collections.Generic;
using System.Linq;

namespace CSharpInheritanceAnalyzer.Model
{
    public static class LinqExtensions
    {
        public static IEnumerable<T> Concat<T>(this IEnumerable<T> items, T item)
        {
            foreach (var item1 in items)
            {
                yield return item1;
            }
            yield return item;
        }
    }
}