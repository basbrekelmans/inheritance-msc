using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Forms;
using CSharpInheritanceAnalyzer.Model.Sloc;
using CSharpInheritanceAnalyzer.ViewModel;
using DataFormats = System.Windows.DataFormats;
using DragDropEffects = System.Windows.DragDropEffects;
using DragEventArgs = System.Windows.DragEventArgs;

namespace CSharpInheritanceAnalyzer
{
    /// <summary>
    ///     Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private int _javaFileCount;

        public MainWindow()
        {
            InitializeComponent();
            NativeHelper.EnableDragDropForWindow(this);
            this.KeyDown += MainWindow_KeyDown;

        }

        void MainWindow_KeyDown(object sender, System.Windows.Input.KeyEventArgs e)
        {
            if (e.Key == System.Windows.Input.Key.Delete)
            {
                ViewModel.DeleteCurrent();
            }
        }

        private MainViewModel ViewModel
        {
            get { return (MainViewModel) this.DataContext; }
        }

        private void DragEnterWindow(object sender, DragEventArgs e)
        {
            bool isDropAllowed;
            if (e.Data.GetDataPresent(DataFormats.FileDrop, true))
            {
                var filenames =
                    e.Data.GetData(DataFormats.FileDrop, true) as string[];

                isDropAllowed = filenames != null
                                && filenames.Any(IsSolution);
            }
            else
            {
                isDropAllowed = false;
            }

            if (!isDropAllowed)
            {
                e.Effects = DragDropEffects.None;
                e.Handled = true;
            }
        }

        private static bool IsSolution(string filename)
        {
            return string.Equals(Path.GetExtension(filename), ".sln",
                StringComparison.InvariantCultureIgnoreCase);
        }

        private void OnDrop(object sender, DragEventArgs e)
        {
            if (e.Data.GetDataPresent(DataFormats.FileDrop, true))
            {
                var fileNames =
                    e.Data.GetData(DataFormats.FileDrop, true) as string[];

                if (fileNames != null)
                {
                    foreach (var fileName in fileNames.Where(IsSolution))
                    {
                        ViewModel.AddSolutionFromFileName(fileName);
                    }
                }
            }
        }

        private void AddButtonClick(object sender, RoutedEventArgs e)
        {
            var dialog = new Microsoft.Win32.OpenFileDialog();
            dialog.Filter = "Any File (*.sln, *.slncollection)|*.sln;*.slncollection|Solution Files (*.sln)|*.sln|Solution Collection (*.slncollection)|*.slncollection";
            dialog.Multiselect = true;
            if (dialog.ShowDialog() == true)
            {
                foreach (var fileName in dialog.FileNames)
                {
                    if (Path.GetExtension(fileName) == ".sln")
                    {
                        ViewModel.AddSolutionFromFileName(fileName);
                    }
                    else
                    {
                        var names = File.ReadAllLines(fileName);
                        foreach (var name in names)
                        {
                            ViewModel.AddSolutionFromFileName(name);
                        }
                    }

                }
            }
        }

        private async void JavaLocClick(object sender, RoutedEventArgs e)
        {
            var selector = new FolderBrowserDialog();
            if (selector.ShowDialog() == System.Windows.Forms.DialogResult.OK)
            {
                var folder = selector.SelectedPath;
                var javaFiles = Directory.GetFiles(folder, "*.java", SearchOption.AllDirectories);
                _javaFileCount = javaFiles.Length;
                JavaProgress.Value = 10;
                ProgressText.Text = string.Format("{0} files", javaFiles.Length);
                var result = await Task.Run(() => javaFiles.Select(s => LineCounter.CountLines(File.ReadAllLines(s))).ToList());
                var output = result.Aggregate((a, b) => a + b);
                const string targetDirectory = @"C:\InheritanceTest\Output\";
                string targetFile = new DirectoryInfo(folder).Name + "-loc.csv";
                using (
                    var writer =
                        new StreamWriter(new FileStream(Path.Combine(targetDirectory, targetFile), FileMode.Create)))
                {
                    writer.WriteCsvLine("LinesOfCode", "LinesOfComment", "BlankLines");
                    writer.WriteCsvLine(output.CodeCount, output.CommentCount, output.BlankCount);
                }
                JavaProgress.Value = 100;
                ProgressText.Text = "Done";

            }
        }
    }
}