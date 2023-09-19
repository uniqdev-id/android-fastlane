[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#<your-repository-url>)     

# android-fastlane
you can use the image in gitpod

### PATH
 - Flutter sdk path located in **/home/gitpod/flutter**     

to speed up the build process, you can cache the following directories:     
    - /home/gitpod/.pub-cache     
    - /home/gitpod/flutter/bin/cache        



#### Example Usage
you can build/run app using this docker image on your local computer as well,        

```
docker run -t -v /workspace/flutter-cache/.pub-cache:/home/gitpod/.pub-cache -v  /workspace/flutter-cache/cache:/home/gitpod/flutter/bin/cache -w /app -v ${PWD}:/app/ uniqdev/android-fastlane:flutter-gitpod-jdk11-latest flutter build apk --release
```     

note:      
**/workspace/flutter-cache** : is your directory to cache flutter dependencies (for all project), you can change it as you wish    

