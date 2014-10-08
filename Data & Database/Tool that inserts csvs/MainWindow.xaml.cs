using InheritanceInsertion.ViewModel;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace InheritanceInsertion
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        private async void InsertAll_Click(object sender, RoutedEventArgs e)
        {
            Progress.Visibility = Visibility.Visible;
            var viewModel = DataContext as MainViewModel;
            double completed = 0;

            foreach (var item in viewModel.Projects.Where(p => !p.Exists).ToList())
            {
                await item.UploadDataAsync();
                completed ++;
                Progress.Value = completed / viewModel.Projects.Count;
            }
        }

        private async void InsertSelected_Click(object sender, RoutedEventArgs e)
        {
            Progress.Visibility = Visibility.Visible;
            var viewModel = DataContext as MainViewModel;
            double completed = 0;

            foreach (var item in this.Grid.SelectedItems.OfType<ProjectViewModel>().ToList())
            {
                await item.UploadDataAsync();
                completed++;
            }

        }
    }
}
