# Using Terraform

## Locally using Command Line

This document assumes the reader is familiar with the Terraform CLI, has installed the appropriate version locally on their development machine and included the path to the executable in the relevant environment variable.

You will also need to have installed the [Azure PowerShell CLI](https://docs.microsoft.com/cli/azure/) tools.

**If the files you are using are hosted in a source control system, you may need to carry out appropriate initialisation steps before running the following commands.**

1. First up, open a command window and navigate to the working directory containing the root terraform configuration you are going to use:

   ```
   cd "xxx\xxx"
   ```

2. The next step is to log in to the Azure subscription to which you intend to deploy, and in which the terraform state file is/will be located stored.

   a. Open up a command window and enter:

      ```
      az login
      ```

      A browser window will be opened and you will be redirected to a page where you can log in.  In the success case, the command window will then list all the subscriptions to which you have access.  Locate the appropriate subscription and note the value for the "id" attribute.  If the subscriptions are not listed, you can use the 'az account list' command instead.

   b. You now need to set the context for the Azure CLI tooling by running (where "xxx...xxx" is the placeholder for the "id" attribute value you noted previous:

      ```
      az account set --subscription "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"
      ```

      Alternatively, if you prefer to use the "name" of the subscription, you can use that in place of the "id" instead

3. Now we need to [initalise the directory ready for use by Terraform](https://www.terraform.io/docs/cli/commands/init.html).  If you've done this already, you might be able to safely skip this step, but given it is an idempotent operation there is no harm in running it again.

   You will need to know a few details to give to Terraform so it can locate/create the infrastructure state file (replace the xxx placeholders with the appropriate values).

   ```
   terraform init -backend-config="storage_account_name=xxx" -backend-config="container_name=xxx" -backend-config="key=xxx" -backend-config="resource_group_name=xxx"
   ```

   Terraform will now search for the relevant backend configuration block in the configuration files and locate any module references.  It will then initialise and download anything it needs into the .terrafrom directory.  It will also create a lock file called .terraform.lock.hcl

   In the success case, a command line message along the lines of "Terraform has been successfully initialised!" will be reported.

4. Now everything is initialised, the next step is to validate the configuration files

   ```
   terraform validate
   ```

   In the success case, a command line message along the lines of "Success!  The configuration is valid." will be reported.

5. In our case, the configuration references variables that must be provided on the command line.  There are a few ways you can supply these depending on whether you are using the CLI tools in interactive mode or not.  For ease of documentation, we'll supply them on the command line.

6. This next step is optional, but certainly one I tend to employ myself by way of a sanity check (and most certainly if using in an automated CI pipeline).  We'll ask Terraform to [check the state file and compare it against the configuration](https://www.terraform.io/docs/cli/commands/plan.html) to identify any changes that need to be made:

   ```
   terraform plan -var "<<var_name>>=<<var-value>>"
   ```

   The resulting plan can be saved to a file for further consumption, but if running interactively, the proposed changes are written to the command window in a human-readable format.

   Give the plan a once over and make sure they are as you'd expect.  If the state file is out-of-whack you can use the -refresh=true argument, but best to ensure all infrastructure configuration is handled by terraform once you start down that path.

7. Once you have inspected the plan and concluded all is ok, the next step is to push these changes out to Azure:

   ```
   terraform apply -var "<<var_name>>=<<var-value>>"
   ```

   If you created a plan file then this is of course the time to pass it to the 'apply' command, otherwise it is going to plan again and if anything has changed since you inspected it them you might be in for a bit of a surprise!

   The above command will output the plan and ask you to confirm all is ok before proceeding.  If you are not running in interactive mode, ensure you pass the command line argument to skip this step.

   In the success case, the relevant changes will be made and reported back via the command window.

## Summary

Please do explore the options available to you in Terraform as there are other commands and arguments that haven't been explored here.  For example, you could use workspaces to manage multiple environments and the destroy command to clean one up.

Automating these deployments in a DevOps pipeline is covered in the documentation stored in the FutureNHS open documents repository on GitHub.




