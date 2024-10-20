using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;

public static class BuildTool
{
    /// <summary>
    /// Get command line argument
    /// </summary>
    static KeyValuePair<string, string>? GetCommandLineArg(string key)
    {
        var args = Environment.GetCommandLineArgs();
        for (int i = 0; i < args.Length; i++)
        {
            if (args[i].StartsWith("-") &&
                args[i].TrimStart('-') == key)
            {
                var value = args.Length > i + 1 && !args[i + 1].StartsWith("-") ? args[i + 1] : string.Empty;
                UnityEngine.Debug.Log($"ARG: {args[i]} {value}");
                return new KeyValuePair<string, string>(key, value);
            }
        }

        return null;
    }

    /// <summary>
    /// Get scene paths
    /// </summary>
    static string[] GetScenePaths() => EditorBuildSettings.scenes
            .Where(scene => scene.enabled)
            .Select(scene => scene.path)
            .ToArray();

    /// <summary>
    /// returns false if one or more required environment variables are not defined
    /// </summary>
    static bool EnvironmentVariablesMissing(string[] envvars)
    {
        string value;
        bool missing = false;
        foreach (string envvar in envvars)
        {
            value = Environment.GetEnvironmentVariable(envvar);
            if (value == null)
            {
                Console.Write("BUILD ERROR: Required Environment Variable is not set: ");
                Console.WriteLine(envvar);
                missing = true;
            }
        }

        return missing;
    }

    /// <summary>
    /// Add define symbols as soon as Unity gets done compiling.
    /// </summary>
    static void AddDefineSymbols(string[] symbols)
    {
        if (symbols?.Any() != true)
            return; //nothing to add

        var allDefines = PlayerSettings.GetScriptingDefineSymbolsForGroup(EditorUserBuildSettings.selectedBuildTargetGroup).Split(';').ToList();
            allDefines.AddRange(symbols.Except(allDefines));
        PlayerSettings.SetScriptingDefineSymbolsForGroup(
            EditorUserBuildSettings.selectedBuildTargetGroup,
            string.Join(";", allDefines.ToArray()));
    }


    static int ExportXcodeProjectCore()
    {
        EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.iOS, BuildTarget.iOS);

        EditorUserBuildSettings.symlinkSources = true;
        //EditorUserBuildSettings.development = true;
        //EditorUserBuildSettings.allowDebugging = true;

        //Add user-specified symbols for script compilation
        var defines = GetCommandLineArg("define")?.Value.Split('.');
        AddDefineSymbols(defines);

        //Get the apk file to be built from the command line argument
        var outputPath = GetCommandLineArg("outputPath")?.Value ?? string.Empty;
        var result = BuildPipeline.BuildPlayer(GetScenePaths(), outputPath, BuildTarget.iOS, BuildOptions.None)?.summary.result;
        return result == BuildResult.Succeeded ? 0 : -1;
    }

    /// <summary>
    /// This method registers a set of methods to call when the Version Handler has enabled all
    /// plugins in a project.
    /// </summary>
    public static void BuildAndroid()
    {
        var enableResolver = GetCommandLineArg("enableResolver");
        if (enableResolver != null)
        {
            ResolutionRunner.OnResolutionComplete = BuildApk;
            ResolutionRunner.EnableResolver();
        }
        else
        {
            BuildApk();
        }
    }

    /// <summary>
    /// Main entry point
    /// - check if all required environment variables are defined
    /// - configure the android build
    /// - build the apk(path read from the command line argument)
    /// </summary>
    static int BuildApkCore()
    {
        UnityEngine.Debug.Log("Ready to build .apk");

        string[] envvars = new string[]
        {
            "ANDROID_KEYSTORE_NAME",
            "ANDROID_KEYSTORE_PASSWORD",
            "ANDROID_KEYALIAS_NAME",
            "ANDROID_KEYALIAS_PASSWORD",
            "ANDROID_HOME",
            "ANDROID_NDK_HOME",
            "JAVA_HOME"
        };
        if (EnvironmentVariablesMissing(envvars))
            return -1; // note, we can not use Environment.Exit(-1) - the buildprocess will just hang afterwards

        EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.Android, BuildTarget.Android);
        //Available Playersettings: https://docs.unity3d.com/ScriptReference/PlayerSettings.Android.html

        //set BuildNumber
        int bundleVersionCode;
        var buildNumber = GetCommandLineArg("buildNumber");
        if (buildNumber == null || !int.TryParse(buildNumber?.Value, out bundleVersionCode))
            throw new FormatException($"BuildNumber has to be an integer: {buildNumber}");
        PlayerSettings.Android.bundleVersionCode += bundleVersionCode % 1000;

        //set the other settings from environment variables
        PlayerSettings.Android.keystoreName = Environment.GetEnvironmentVariable("ANDROID_KEYSTORE_NAME");
        PlayerSettings.Android.keystorePass = Environment.GetEnvironmentVariable("ANDROID_KEYSTORE_PASSWORD");
        PlayerSettings.Android.keyaliasName = Environment.GetEnvironmentVariable("ANDROID_KEYALIAS_NAME");
        PlayerSettings.Android.keyaliasPass = Environment.GetEnvironmentVariable("ANDROID_KEYALIAS_PASSWORD");

        EditorPrefs.SetString("AndroidSdkRoot", Environment.GetEnvironmentVariable("ANDROID_HOME"));
        EditorPrefs.SetString("AndroidNdkRoot", Environment.GetEnvironmentVariable("ANDROID_NDK_HOME"));
        EditorPrefs.SetString("JdkPath", Environment.GetEnvironmentVariable("JAVA_HOME"));

        //Add user-specified symbols for script compilation
        var defines = GetCommandLineArg("define")?.Value.Split('.');
        AddDefineSymbols(defines);

        //Get the apk file to be built from the command line argument
        var outputPath = GetCommandLineArg("outputPath")?.Value ?? string.Empty;
        string apk = $"MyApp_{PlayerSettings.Android.bundleVersionCode / 1000}_{bundleVersionCode % 1000}.apk";
        var result = BuildPipeline.BuildPlayer(GetScenePaths(), System.IO.Path.Combine(outputPath, apk), BuildTarget.Android, BuildOptions.None)?.summary.result;
        return result == BuildResult.Succeeded ? 0 : -1;
    }

    static void BuildApk() => EditorApplication.Exit(BuildApkCore());
	
	public static void ExportXcodeProject() => EditorApplication.Exit(ExportXcodeProjectCore());
}