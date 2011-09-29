###################
Creating a New App
###################

To build a new app using the Kurogo framework, our recommendation is to make a
copy of the entire Universitas directory from a fresh git clone and replace the
string "Universitas" with the bundle name of your app in the .pbxproj file. 
For example, to create a new project MyApp: ::

    cd /path/to/Kurogo-iOS/Projects
    cp -r Universitas MyApp
    cd MyApp
    mv Universitas.xcodeproj MyApp.xcodeproj
    sed -i .bak 's/Universitas/MyApp/g' MyApp.xcodeproj/project.pbxproj

Open Kurogo.xcworkspace (under the Projects directory) in Xcode. In the File
menu, select 'Add Files to "Kurogo"' and locate MyApp.xcodeproj in the Projects
directory.

Files in the new MyApp directory under Projects are located under the MyApp 
project's Site group in Xcode.


