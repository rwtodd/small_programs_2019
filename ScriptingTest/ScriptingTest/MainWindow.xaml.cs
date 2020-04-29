using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using Microsoft.CodeAnalysis.CSharp.Scripting;
using Microsoft.CodeAnalysis.Scripting;

namespace ScriptingTest
{

    public class RunArgs
    {
        public int X;
        public int Y;
    }

    public interface IAlgorithm
    {
        int GetAnswer();
    }

    public class Mandel : IAlgorithm
    {
        private int myX;

        public Mandel(int x)
        {
            myX = x;
        }
        public int GetAnswer()
        {
            return 10 + myX;
        }
    }
    public class Julia : IAlgorithm
    {
        private int myX;

        public Julia(int x)
        {
            myX = x;
        }
        public int GetAnswer()
        {
            return 100 + myX;
        }
    }

    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private int count = 0;

        public MainWindow()
        {
            InitializeComponent();
        }

        /// <summary>
        /// Run the user-given script 10 times, with different inputs, and print the results.
        /// </summary>
        /// <param name="sender">WPF arg</param>
        /// <param name="e">WPF arg</param>
        private async void Button_Click(object sender, RoutedEventArgs e)
        {
            var globs = new RunArgs { X = 1, Y = 2 };
            var retStr = new StringBuilder();
            try
            {
                var script = CSharpScript.Create<IAlgorithm>(
                    CodeBox.Text, 
                    options: ScriptOptions.Default.WithReferences(typeof(ScriptingTest.IAlgorithm).Assembly).WithImports("ScriptingTest"), 
                    globalsType: typeof(RunArgs));
                script.Compile();
                var state = await script.RunAsync(globs);
                retStr.AppendLine($"{++count} Answer:  {state.ReturnValue.GetAnswer()}");
                ResultsBox.Text = retStr.ToString();
            }
            catch (Exception ex)
            {
                ResultsBox.Text = ex.ToString();
            }

        }
    }
}
