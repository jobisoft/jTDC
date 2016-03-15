# jAnalyzer

Tool to analyze raw data files (dat files) created by [jDaqLite](https://github.com/jobisoft/jDaqLite) (Standalone DAQ for example implementation of the [jTDC](https://github.com/jobisoft/jTDC)).

It uses the ROOT framework to extract and display the timing information from the data and also calculates the width of each TDC bin according to the *white noise assumption* as used by the jTDC modules. It creates a root file containing some basic timing plots.

```
./jAnalizeer filename [options]
```

If no options are provided, a list of all available options is shown.
