########
Modules
########

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

------------------------
The *<Name>Module* class
------------------------

This file must subclass KGOModule, and override the following methods: ::

    - (UIViewController *)modulePage:(NSString *)pageName
                              params:(NSDictionary *)params

The module can support federated search by overriding the methods: ::

    - (BOOL)supportsFederatedSearch
    - (void)performSearchWithText:(NSString *)searchText
                           params:(NSDictionary *)params
                         delegate:(id<KGOSearchResultsHolder>)delegate;




