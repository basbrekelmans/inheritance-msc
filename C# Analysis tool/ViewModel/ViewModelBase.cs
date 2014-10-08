using System.Runtime.CompilerServices;
using GalaSoft.MvvmLight;

namespace CSharpInheritanceAnalyzer.ViewModel
{
    public  abstract class ViewModelBaseEx : ViewModelBase
    {
        protected void Set<T>(ref T field, T value, [CallerMemberName] string propertyName = null)
        {
            base.Set(propertyName, ref field, value);
        }
    }
}