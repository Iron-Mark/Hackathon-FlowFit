# SnakeYAML contains optional JavaBeans integration points that are not present
# on Android. R8 only needs these warnings suppressed for release shrinking.
-dontwarn java.beans.BeanInfo
-dontwarn java.beans.FeatureDescriptor
-dontwarn java.beans.IntrospectionException
-dontwarn java.beans.Introspector
-dontwarn java.beans.PropertyDescriptor
