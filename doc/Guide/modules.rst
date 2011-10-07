################
Writing Modules
################

In Kurogo iOS, each module consists of the following classes:

* *<Name>Module* - a subclass of KGOModule
* Any number of view controllers (including zero)
* A Core Data model and associated class files (optional)
* A folder of images and other resources (optional)

All module files except the resources are placed in their own directory under
the top-level Modules directory (if a framework module) or under 
Projects/<ProjectName>/Modules (if a custom module). Projects may also override
framework modules, either by adding subclasses in 
Projects/<ProjectName>/Modules or simply including only 
Projects/<ProjectName>/Modules and excluding the top level directory in Xcode.

=========================
The *<Name>Module* class
=========================

This file must subclass KGOModule, and override the following methods: ::

    - (UIViewController *)modulePage:(NSString *)pageName
                              params:(NSDictionary *)params

The UIViewController returned will be shown to the user by the app delegate 
using the app's navigation method (i.e. if there is a UINavigationController, 
the view controller will be pushed on the navigation stack).

The module can support federated search by overriding the methods: ::

    - (BOOL)supportsFederatedSearch
    - (void)performSearchWithText:(NSString *)searchText
                           params:(NSDictionary *)params
                         delegate:(id<KGOSearchResultsHolder>)delegate;

See :ref:`libraries-search` for more details.

=========================
Creating a New Module
=========================

Suppose the name of the new module is Demo.

1. In the filesystem, create a directory called Demo in the project's 
   Modules directory.

2. Add the directory as a group to Xcode under the Site group.

3. In Xcode, create a new Objective-C class called DemoModule in the new Demo 
   group.

4. Convert the class into a subclass of KGOModule.

5. (Unless the module has no view, like the External URL module,) Create a 
   view controller representing the home screen of the new module.

6. Implement *-modulePage:params:*, for example ::

    - (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params
    {
        UIViewController *vc = nil;
        if ([pageName isEqualToString:LocalPathPageNameHome]) {
            *vc = [[[DemoViewController alloc] initWithNibName:@"DemoViewController" 
                                                        bundle:nil] autorelease];
        }
        return vc;
    }



