using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using Microsoft.CodeAnalysis.CSharp.Scripting;

namespace ScriptingTest
{

    public class RunArgs
    {
        public double X;
        public double Y;
        public double EscapeVal;
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
            var globs = new RunArgs { X = 0.1, Y = 0.1, EscapeVal = 64 };
            var retStr = new StringBuilder();
            try
            {
                var script = CSharpScript.Create<double>(CodeBox.Text, globalsType: typeof(RunArgs));
                script.Compile();
                for (int i = 0; i < 10; ++i)
                {
                    globs.X += 0.05;
                    globs.Y += 0.025;
                    var state = await script.RunAsync(globs);
                    retStr.AppendLine($"{++count} Answer:  {state.ReturnValue}");
                }
                ResultsBox.Text = retStr.ToString();
            }
            catch (Exception ex)
            {
                ResultsBox.Text = ex.ToString();
            }

        }
    }
}
