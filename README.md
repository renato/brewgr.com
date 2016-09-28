What is Brewgr?
======
Brewgr is a free home brewing web application located at http://brewgr.com.  It offers homebrewers numerous features for creating recipes, tracking brew day, and collaborating with others.  Brewgr is now open source with the hopes that the community will contribute features and fixes so it can continue to grow and be a valuable tool for homebrewers.

Getting Started
----------------------------
If you're interested in contributing to Brewgr (and we hope you do), please pick something that interests you from the [Issue List](https://github.com/ctorx/brewgr.com/issues) and get started.  We'll try our best to merge any pull-requests that add value, but please, before embarking on a major new feature, please post it as an issue to get discussion going first.

Development Environment Setup
========

Technologies:
----------------------------
* Microsoft ASP.NET MVC - http://www.asp.net/mvc
* Microsoft Entity Framework - http://www.asp.net/entity-framework
* AutoMapper - https://github.com/AutoMapper/AutoMapper
* Ninject - https://github.com/ninject/ninject
* Exceptional - https://github.com/NickCraver/StackExchange.Exceptional
* Fluent Validation - https://github.com/JeremySkinner/FluentValidation
* Image Resizer - https://github.com/imazen/resizer
* jQuery - https://github.com/jquery/jquery
* Various jQuery plugins

Database Setup
--------------------------
1. Fork and clone the repository on your machine
2. Navigate to the "Setup\Database" folder in the repository root and follow the directions in the  [README](Setup/Database/README.md).

Connection String Setup
----------------------------
1. Determine what your valid connection string is based upon your database setup.  If you need help with the connection string, check out http://www.connectionstrings.com/sql-server/.
2. Create a system Enviornment Variable named "Brewgr_ConnectionString" and set the value to the connection string determined in step 1 above. 
3. You may need to reboot your machine for Visual Studio and IIS Express to recognize the variable.

Alternative Database: PostgreSQL
----------------------------
1. Use Nuget and add the packages `Npgsql` and `EntityFramework6.Npgsql` to Brewgr.Web
2. Create a system Environment Variable called "Brewgr_ProviderName" and set it to "Npgsql"
3. Determine what your valid Npgsql connection string is. If you need help, check out http://www.connectionstrings.com/npgsql/
4. Change the "Brewgr_ConnectionString" to the connection string determined in step 3 above

Host File Entry
----------------------------
The development environment uses an artificial host name dev.brewgr.com.  In order to make this work, you'll need create a host file entry on your development machine that points dev.brewgr.com to 127.0.0.1.

```
127.0.0.1	dev.brewgr.com
```

IIS Express Setup
----------------------------
In order to make IIS Express play nice with the host name, you'll need to modify the applicationhost.config file to look like the following:

```xml
 <site name="dev.brewgr.com" id="1" serverAutoStart="true">
 	<application path="/">
 		<virtualDirectory path="/" physicalPath="{repo root path}\Brewgr.Web" />
 	</application>
 	<bindings>
 		<binding protocol="http" bindingInformation=":80:dev.brewgr.com" />
 	</bindings>
 </site>
```
If you're using Visual Studio 2015, you can modify the applicationhost.config file that gets created in the .vs folder for the Brewgr.Web project, but you'll need to launch the solution once first and dismiss the localhost warning.  At this point the file will be created.  Make the changes and either reload the Brewgr.Web project or restart Visual Studio.

If you're not using Visual Studio 2015, you will need to modify the applicationhost.config that is located in the Documents\IISExpress folder under your account folder.  

Test Your Setup
----------------------------
1. Launch Visual Studio (with elevated access -- necessary for the non-localhost URL)
2. Open the [Brewgr.Web.sln](Brewgr.Web.sln) file.  You'll need to make sure that you have Nuget installed and pull down the dependency packages.  NOTE: Brewgr uses a packages folder that is at the same level as the solution folder, as noted in the Nuget.config file.
3. If you can build the solution sucessfully, you should be good to go.
 
Please let us know if you encounter setup errors and we'll help you out.  Cheers!


---------
Brewgr is Copyright &copy; 2011-2015 [Matthew Marksbury](https://github.com/ctorx) and [Jason Zimmerman](https://github.com/SingleSpeed) and other contributors under the [GNU General Public License v3.0](LICENSE.txt).

