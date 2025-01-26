using System;
using System.Linq;
using Nuke.Common;
using Nuke.Common.CI;
using Nuke.Common.CI.GitHubActions;
using Nuke.Common.Execution;
using Nuke.Common.IO;
using Nuke.Common.ProjectModel;
using Nuke.Common.Tooling;
using Nuke.Common.Utilities.Collections;
using static Nuke.Common.EnvironmentInfo;
using static Nuke.Common.IO.PathConstruction;

[GitHubActions("build", 
   GitHubActionsImage.UbuntuLatest,    
   InvokedTargets = new[] { nameof(Compile), nameof(Pack) },
   OnWorkflowDispatchRequiredInputs = [ "OpenRGBVersion" ])]
class Build : NukeBuild
{
    public static int Main () => Execute<Build>(x => x.Compile);

   [Parameter] readonly string OpenRGBVersion;

    Target Clean => _ => _
        .Before(Restore)
        .Executes(() =>
        {
        });

    Target Restore => _ => _
        .Executes(() =>
        {
        });

    Target Compile => _ => _
        .DependsOn(Restore)
        .Executes(() =>
        {
           Console.WriteLine($"Version is: {OpenRGBVersion}");
        });

   Target Pack => _ => _
         .DependsOn(Compile)
         .Executes(() =>
         {
         });
}
