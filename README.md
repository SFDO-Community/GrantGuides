# GrantGuides

Community-based organizations are often small and scrappy with limited time and resources. They need funding in order to continue to serve their communities and oftentimes secure that funding through grants. Global philanthropic funding (https://www.mckinsey.com/business-functions/sustainability/our-insights/its-time-for-philanthropy-to-step-up-the-fight-against-climate-change) related to climate change is minimal compared with the scale of the challenge and securing that funding is competitive. Grant writing is a long and tedious process that is often not a staffed position at a CBO. There is also a considerable amount of turnover at these smaller organizations which means institutional knowledge often leaves with that turnover. The staff member writing grants needs assistance crafting their message and telling their story in order to write winning grants and secure funding. 

## Solution Overview 

### Epic
In order to write winning grants, as a grant writer, I need assistance assembling the necessary content and telling my best story. 

### Use Case
In order to repurpose content from my previously submitted grant applications, as a grant writer, I need a way to store and quickly access my past grant proposal content.

## Technical Design

### UX Storyboard Prototype

![GrantGuides Storyboard UX](https://github.com/Salesforce-org-Impact-Labs/GrantGuides/images/GrantGuides_Storyboard_Flow.png)

### Data Model

![Grants app Data Model](https://github.com/Salesforce-org-Impact-Labs/GrantGuides/images/Grants_App_Data_Model.png)

### Grant Preview/Export
Preview grant document is implemented using VisualForce page rendered as PDF that enables user to view and download a document.

This page `GGW_GrantPreview` implimented using standard APEX controller extension for the reason to use this page as custom action on Grant record page as well as stand alone VisualForce Tab.

The HTML/CSS styles for this page `GGW_GrantPreview` are managed as static resource. The CSS file is in a folder `resources/css/ggw_grant_preview.css`

## Salesforce DX Project: Next Steps

Now that you’ve created a Salesforce DX project, what’s next? Here are some documentation resources to get you started.

## How Do You Plan to Deploy Your Changes?

Do you want to deploy a set of changes, or create a self-contained application? Choose a [development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models).

## Configure Your Salesforce DX Project

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

## Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
