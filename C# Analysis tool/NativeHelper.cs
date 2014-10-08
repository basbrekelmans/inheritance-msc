using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Interop;

namespace CSharpInheritanceAnalyzer
{
    internal class NativeHelper
    {
        private enum MessageFilterInfo : uint
        {
            None = 0, AlreadyAllowed = 1, AlreadyDisAllowed = 2, AllowedHigher = 3
        };

        private enum ChangeWindowMessageFilterExAction : uint
        {
            Reset = 0, Allow = 1, DisAllow = 2
        };

        [DllImport("user32")]
        private static extern bool ChangeWindowMessageFilterEx(IntPtr hWnd, uint msg, ChangeWindowMessageFilterExAction action, ref ChangeFilterStruct changeInfo);

        [StructLayout(LayoutKind.Sequential)]
        private struct ChangeFilterStruct
        {
            public uint size;
            public MessageFilterInfo info;
        }

        private const uint WmDropFiles = 0x233,
            WmCopyData = 0x4A,
            OtherOne = 0x49;

        public static void EnableDragDropForWindow(Window window)
        {
            var source = new WindowInteropHelper(window);
            var changes = new ChangeFilterStruct();
            ChangeWindowMessageFilterEx(source.Handle, WmDropFiles, ChangeWindowMessageFilterExAction.Allow, ref changes);
            ChangeWindowMessageFilterEx(source.Handle, WmCopyData, ChangeWindowMessageFilterExAction.Allow, ref changes);
            ChangeWindowMessageFilterEx(source.Handle, OtherOne, ChangeWindowMessageFilterExAction.Allow, ref changes);
        }
    }
}
