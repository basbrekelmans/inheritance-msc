using GalaSoft.MvvmLight;

namespace InheritanceInsertion.ViewModel
{
    public class FileViewModel : ObservableObject
    {
        private readonly string _dataType;
        private bool _exists;

        public FileViewModel(string dataType)
        {
            _dataType = dataType;
        }

        public string DataType
        {
            get { return _dataType; }
        }

        public bool Exists
        {
            get { return _exists; }
            set { Set(() => Exists, ref _exists, value); }
        }
    }
}