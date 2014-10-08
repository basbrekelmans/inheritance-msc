using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using CSharpInheritanceAnalyzer.Collections;
using CSharpInheritanceAnalyzer.Properties;
using GalaSoft.MvvmLight;

namespace CSharpInheritanceAnalyzer.ViewModel
{
    /// <summary>
    ///     This class contains properties that the main View can data bind to.
    ///     <para>
    ///         Use the <strong>mvvminpc</strong> snippet to add bindable properties to this ViewModel.
    ///     </para>
    ///     <para>
    ///         You can also use Blend to data bind with the tool's support.
    ///     </para>
    ///     <para>
    ///         See http://www.galasoft.ch/mvvm
    ///     </para>
    /// </summary>
    public class MainViewModel : ViewModelBase
    {
        private readonly ObservableCollection<Solution> _finishedItems;
        private readonly ObservableQueue<Solution> _solutionQueue = new ObservableQueue<Solution>();
        private CancellationTokenSource _cts;

        /// <summary>
        ///     Initializes a new instance of the MainViewModel class.
        /// </summary>
        public MainViewModel()
        {
            _finishedItems = new ObservableCollection<Solution>();
            if (IsInDesignMode)
            {
                _solutionQueue.Enqueue(new Solution("Solution1.sln")
                {
                    Status = SolutionStatus.Running
                });
                _solutionQueue.Enqueue(new Solution("Bla.sln")
                {
                    Status = SolutionStatus.Running
                });
                _solutionQueue.Enqueue(new Solution("Test Project.sln"));
                _solutionQueue.Enqueue(new Solution("Price Management.sln"));
            }
            else
            {
                Settings settings = Settings.Default;
                settings.Upgrade();
                if (settings.UnfinishedSolutionFileNames != null)
                {
                    foreach (string unfinishedSolutionFileName in settings.UnfinishedSolutionFileNames)
                    {
                        if (File.Exists(unfinishedSolutionFileName))
                            SolutionQueue.Enqueue(new Solution(unfinishedSolutionFileName));
                    }
                }
                Run();
            }
        }

        public ObservableQueue<Solution> SolutionQueue
        {
            get { return _solutionQueue; }
        }

        public ObservableCollection<Solution> FinishedItems
        {
            get { return _finishedItems; }
        }

        public void AddSolutionFromFileName(string fileName)
        {
            Settings settings = Settings.Default;
            if (settings.UnfinishedSolutionFileNames == null)
            {
                settings.UnfinishedSolutionFileNames = new StringCollection();
            }
            if (!settings.UnfinishedSolutionFileNames.Contains(fileName))
            {
                settings.UnfinishedSolutionFileNames.Add(fileName);
            }
            settings.Save();
            _solutionQueue.Enqueue(new Solution(fileName));
        }

        private async void Run()
        {
            while (true)
            {
                if (_solutionQueue.Count > 0)
                {
                    _cts = new CancellationTokenSource();
                    Solution solution = _solutionQueue.Peek();
                    await solution.AnalyzeAsync(_cts.Token);
                    DequeueSolution();
                    _cts = null;
                }
                else
                {
                    await Task.Delay(500);
                }
            }
        }

        private void DequeueSolution()
        {
            if (_solutionQueue.Count > 0)
            {
                Solution completed = _solutionQueue.Dequeue();
                FinishedItems.Add(completed);
                Settings.Default.UnfinishedSolutionFileNames.Remove(completed.FilePath);
                Settings.Default.Save();
            }
        }

        public void DeleteCurrent()
        {
            if (_cts != null)
            {
                _cts.Cancel();
            }
            DequeueSolution();
        }
    }
}