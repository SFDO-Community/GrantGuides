# Grants Content Kit

Community-based organizations are often small and scrappy with limited time and resources. They need funding in order to continue to serve their communities and oftentimes secure that funding through grants. [Global philanthropic funding](https://www.salesforce.com/news/stories/salesforce-gives-11m-to-restore-ecosystems-and-advance-climate-justice/) related to climate change is minimal compared with the scale of the challenge and securing that funding is competitive. Grant writing is a long and tedious process that is often not a staffed position at a CBO. There is also a considerable amount of turnover at these smaller organizations which means institutional knowledge often leaves with that turnover. The staff member writing grants needs assistance crafting their message and telling their story in order to write winning grants and secure funding. 

## Solution Overview 

The Grants Content Kit helps organizations write award-winning grants faster and more easily. Co-designed and developed by our Community of volunteers who participated in the [Climate Justice Impact Lab](https://www.salesforce.org/blog/impact-labs-three-climate-justice/?_ga=2.248248132.297731808.1659462956-2124390505.1659462956), the Grants Content Kit was developed for community-based organizations focused on climate justice who struggle to tell their story and write winning grants. The kit stores and organizes grant proposal content in Salesforce, allowing grant writers to streamline applications starting with their best content. 

## Technical Design

### UX Storyboard Prototype

![GrantGuides Storyboard UX](https://github.com/Salesforce-org-Impact-Labs/GrantGuides/blob/main/images/GrantGuides_Storyboard_Flow.png?raw=true)

### Data Model

![Grants app Data Model](https://github.com/Salesforce-org-Impact-Labs/GrantGuides/blob/main/images/Grants_App_Data_Model.png?raw=true)

### Grant Preview/Export
Preview grant document is implemented using VisualForce page rendered as PDF that enables user to view and download a document.

This page `GGW_GrantPreview` implimented using standard APEX controller extension for the reason to use this page as custom action on Grant record page as well as stand alone VisualForce Tab.

The HTML/CSS styles for this page `GGW_GrantPreview` are managed as static resource. The CSS file is in a folder `resources/css/ggw_grant_preview.css`

## Salesforce DX Project: Next Steps

The GrantsGuides is a Salesforce DX project that can deploy to a target org in 2 methods.

1. Install as unlocked package: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t8a000001B8qrAAC


2. Deploy as metadata using scratch or developer org.

If you are a developer and want to customize or test-drive this app in a scratch org, this repo provides a helper script that allows for Quick Start. Follow bellow comands to set up a new scratch org.

```
$ git clone https://github.com/Salesforce-org-Impact-Labs/GrantGuides.git

$ cd GrantGuides

$ scripts/dx/dxorg <org alias> <OPTIONAL: days for scratch org. Default 30>
```
After this script executes the new scratch org will be created from your DevHub and source code pushed to new org. At this point you are ready to test and build. Happy blazing new trails.

There are other usefull `sfdx` helper scripts can be found in `scripts/dx` directory:

* `dxtest <org alias>` - Script to run all APEX unit tests on scratch org for this project
* `dxuser <org alias>` - Create a QA/Test ser on scratch org 

Now you have new org and this app deployed, what’s next? Here are some documentation resources to get you started if you are new to SFDX.

### Post Installation requirements
Grants Content Kit app is using Topics to tag content, the target org needs to enable topics feature after installing this package. Enable topics for the org specific for object Content Block: API Name `GGW_Content_Block__c` [How To Enable Topics for objects](https://help.salesforce.com/s/articleView?id=sf.knowledge_topics.htm&type=5)

## How Do You Plan to Deploy Your Changes?

Do you want to deploy a set of changes, or create a self-contained application? Choose a [development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models).

## Configure Your Salesforce DX Project

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

## Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)

## Questions and Community Support
Join the [Grants Content Kit Trailblazer Group](https://trailhead.salesforce.com/trailblazer-community/groups/0F94S000000kJbMSAU?tab=discussion&sort=LAST_MODIFIED_DATE_DESC) to post questions about the solution and collaborate with other members of the community to further build out the solution. The Grants Content Kit is a free and open source solution co-designed and developed by our community. This solution is not actively being supported or developed on by Salesforce Impact Labs.
