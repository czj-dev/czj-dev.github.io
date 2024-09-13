---
layout: post
title: "Android自定义注解"
subtitle: "\"day day up\""
date: 2017-02-06 16:14:12
atuhor: "chenzhaojun"
header_image: "img/home-bg-o.jpg"
tags:
    - Android
---



[TOC]

## 原注解

原注解的作用就是负责注解其他注解，Java5.0提供了四种meta-annotation,用来提供annotation类型的说明。

**java.lang.annotation**

- @Target
- @Retention
- @Document
- @inhrited

### @Target

作用 :  **用于描述注解的使用范围**

**ElementType**取值 :  

1. **CONSTRUCTOR** :  用于描述构造器
2. **FIELD** : 用于描述域
3. **LOCAL_VARIABLE**  :  用于描述局部变量
4. **METHOD** :  用于描述方法
5. **PACKAGE** :  用于描述包
6. **PARAMETER** :  用于描述参数
7. **TYPE** :  用于描述类、接口（包括注解类型）或enum类型声明

像现在我们声明一个`Name`注解，声明的`Target`范围是`TYPE`，也就是说该注解只能在类、接口以及枚举中声明,当我们在其他场景如方法、变量中声明该注解,IDE就会报错。

```java
@Target(ElementType.TYPE)
public @interface Name {
    String value() default "";
}
```



### @Retention

作用 :  **用于描述注解的生命周期**

表明该注解在程序哪一阶段还保留在代码中,**RetentionPoicy**的取值范围 :  

- **SOURCE** :  在源文件中保留，即生成.class后该注解就已经没有在文件中了。
- **CLASS** :  在Class文件中保留。
- **RUNTIME** :  在编译阶段也保留。

我们使用自定义注解时一般使用`RUNTIME`，这样在运行阶段注解处理器就可以通过反射拿到该注解的属性，从而做一些操作。

### @Document

作用 :  **用于给Javadoc工具标记**

`@Documented` 注解表明这个注解应该被 javadoc工具记录. 默认情况下,`javadoc`是不包括注解的. 但如果声明注解时指定了 `@Documented`,则它会被 `javadoc` 之类的工具处理, 所以注解类型信息也会被包括在生成的文档中。



### @Inherited

作用 :  使用此注解声明出来的自定义注解，在使用此自定义注解时，如果注解在类上面时，子类会自动继承此注解，否则的话，子类不会继承此注解。这里一定要记住，使用Inherited声明出来的注解，只有在类上使用时才会有效，对方法，属性等其他无效。



## 自定义注解

### 使用规范

- **成员参数** :  自定义注解的成员参数只能使用byte,short,char,int,long,float,double,boolean 八种基本数据类型 和 String,Enum,Class,annotations 等数据类型,以及这一些类型的数组。
- **访问权限 **:  注解的成员变量只能使用`public`和默认的权限访问符来修饰。
- **value** :  如果只有一个参数最好是将key的名称设置为`value`,这样我们使用注解时候`Annotation(key=Params)`和`Annotation(Params)`是等价的，而且后者更加的方便简介。
- **注解元素的默认值** :  注解元素必须有确定的值，要么在定义注解的默认值中指定，要么在使用注解时指定，非基本类型的注解元素的值不可为null。因此, 使用空字符串或0作为默认值是一种常用的做法。这个约束使得处理器很难表现一个元素的存在或缺失的状态，因为每个注解的声明中，所有元素都存在，并且都具有相应的值，为了绕开这个约束，我们只能定义一些特殊的值，例如空字符串或者负数，一次表示某个元素不存在，在定义注解时，这已经成为一个习惯用法。



### 注解处理类库(运行时注解)

我们定义了注解，并且在给定了属性。肯定要在合适的环境去获取注解的属性来做一些操作。不然就是注释而不是注解了。

java提供了`java.lang.reflect.AnnotatedElement`来帮助我们获取注解的信息，需要注意的是当我们想要读取一个注解时只有设置它的`@Retention`为`RUNTIME`时候我们才可以拿到，因为只有当`Class`被虚拟机装载的时候才其中的`Annotation`才可以被虚拟机拿到，这是阶段已经属于`RUNTIME`。

AnnotatedElement主要的实现类 :  

- **Class：**类定义
- **Constructor：**构造器定义
- **Field：**累的成员变量定义
- **Method：**类的方法定义
- **Package：**类的包定义

**AnnotatedElement **接口提供了四个方法来访问`Annotation`的信息

1. `<T extends Annotation> T getAnnotation(Class<?> annotationClass) `  :  返回程序元素中存在的、指定类型的注解，如果该注解不存在则返回`null`。
2. `Annotation getAnnotation()` :  返回程序元素中所有存在的注解。
3. `boolean is AnnotationPresent(Class<? extends Annotation> annotationClass)` :  判断程序元素中是否包含该注解。
4. `Annotation[] getDeclaredAnnotations()` :  返回直接存在于此元素上的所有注释。与此接口中的其他方法不同，该方法将忽略继承的注释。（如果没有注释直接存在于此元素上，则返回长度为零的一个数组。）该方法的调用者可以随意修改返回的数组；这不会对其他调用者返回的数组产生任何影响。

### 实践

我们通过一个小`demo`来实现注解的声明和使用。

声明一个注解`@Name` :  

```java
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Name {
    String value() default "name";
}
```

定义一个加载名称的方法 :  

```java
    public static void loadName(Class<?> classz) {
      //拿到类中的所有元素
        Field[] fields = classz.getDeclaredFields();
        for (Field field : fields) {
          //判断是否有该注解
            if (field.isAnnotationPresent(Name.class)) {
              //获取该注解的属性
                Name annotation = field.getAnnotation(Name.class);
                System.err.println(annotation.value());
            }
        }
    }
```

创建一个Human来测试 :  

```java
public class Human {

    @Name("小明")
    String FirstHuman;
    @Name()
    String SecondHuman;

    public static void main(String[] args) {
        Human.loadName(Human.class);
    }

    public static void loadName(Class<?> classz) {
        Field[] fields = classz.getDeclaredFields();
        for (Field field : fields) {
            if (field.isAnnotationPresent(Name.class)) {
                Name annotation = field.getAnnotation(Name.class);
                System.err.println(annotation.value());
            }
        }
    }
}

```

输出结果 :  

```java
小明
name
```

可以看到和预期的一样，第二个元素没有指定vlue输出了default。这里我们就完成了简单的自定义注解。

## 编译时注解

自定义注解很常用的一个方式就是通过编译时注解来生产一些工具代码，提升开发效率。有很多第三方框架都使用了编译时注解，例如：

- butterknife 自动生成View初始化和事件绑定的代码
- EventBus3.0+ 方便实现通讯，通过注解自动把需要通讯的方法标识配置和注册
- fragmenttargs 通过注解轻松的配置 Fragment

除了第三方库之外，我们也可以自己通过编译时注解来帮助我们完成一些日常重复编码的工作。

我们通过实现一个简单版本的 ButterKinfe 来学习和了解编译时注解。

###定义自定义注解

创建一个 java-library 来放置我们定义的自定义注解

创建一个注解类 BindView ,声明它的生命周期：

```java
@Target(ElementType.FIELD) //修饰成员变量
@Retention(RetentionPolicy.CLASS) //在编译时保留
public @interface BindView {
    @IdRes int value(); //通过annotation 库的 @IdRes 限定Value只能为资源ID
}

```

这样一个自定义注解就完成了

###处理注解

####注解处理器环境搭建

创建一个 java-library 来放置注解处理器。

编译时注解需要用到注解处理器`processer`，使用它我们需要依赖`auto-service`这个类库

```groovy
api 'com.google.auto.service:auto-service:1.0-rc4'
```

其次我们需要通过注解处理生成中间类，来完成将 View 和成员变量绑定的操作。我们通过 `javapoet`这个库来方便完成，当然也可以通过手写代码的方式来完成。

```groovy
api 'com.squareup:javapoet:1.10.0'
```

创建一个类继承`AbstractProcessor`类并通过`@AutoService`声明实现的接口,之后我们需要实现具体的`process`方法，这里也是我们处理注解的核心部分，需要的注意的是这个方法可能会被多次调用，需要做好去重的准备。

```java
@AutoService(Processor.class)
public class ViewAnnotationProcessor extends AbstractProcessor {
       @Override
    public boolean process(Set<? extends TypeElement> set, RoundEnvironment roundEnvironment) {
        
    }
}
```

在处理注解前还有一些小工作要做，我们需要配置声明这个注解处理器的所需要处理的注解和支持的源码版本。有两种方式实现：

- 注解，可以通过注解`SupportAnnotationTypes`配置我们需要处理的注解，`SupportSourceVersion ` 配置需要处理的 Java 源版本：

  ```java
  @AutoService(Processor.class)
  @SupportAnnotationTypes({"com.example.annotation_compiler.BindView"})
  @SupportSourceVersion(SourceVersion.RELEASE_7)
  public class ViewAnnotationProcessor extends AbstractProcessor {
      ...
  }
  ```

- 重写 `getSupportedAnnotationTypes()`和`getSupportedSourceVersion方法`：

  ```java
      @Override
      public Set<String> getSupportedAnnotationTypes() {
          /*
            tips: getCanonicalName 和 Name 、SimpleName 的区别
            SimpleName 只会返回该类的简称
            getName和getCanonicalName在大多情况下没有区别 它们都都返回 Class 的全类名，
            但在内部类和数组的时候 返回的 Name 形式则不同。
           */
          Set<String> set = new HashSet<>(1);
          set.add(BindView.class.getCanonicalName());
          return set;
      }

      @Override
      public SourceVersion getSupportedSourceVersion() {
          return SourceVersion.latestSupported();
      }
  ```

最后我们重写 `init`  方法，它会在注解处理器被初始化的时候调用，它的参数 ProcessingEnvironment 提供了一系列的帮助类来帮助我们处理注解

```java
 /**
     * 初始化注解类方法
     *
     * @param processingEnvironment environment 提供了一系列帮助类
     *                              Filer 文件相关的辅助类
     *                              Elements 元素相关的辅助类
     *                              Message 日志相关的辅助类
     */
    @Override
    public synchronized void init(ProcessingEnvironment processingEnvironment) {
        super.init(processingEnvironment);
        mFileUtils = processingEnvironment.getFiler();
        mElementUtils = processingEnvironment.getElementUtils();
        mMessager = processingEnvironment.getMessager();
    }
```

#### 处理注解

到此，我们的环境就搭建完成了。开始正式的处理注解，`prosser`方法大致分为两步骤：

1. 收集信息，通过 element 获得我们注解的 value、class、variable 等信息存储起来
2. 收集信息完毕后就可以开始我们的工作，这里我们就开始生成中间类。

#### 收集信息

这里先说明一下 Elment 。注解取得的元素都以 Element 等待处理，它的具体类型与我们通过@Targe 来标记的具有一定的联系，它有以下几个子类：

- VariableElement 表示一个局部变量、枚举、方法或构造函数、
- ExecutableElement 表示某个类或接口的方法、构造方法和注释类型元素
- TypeElement 表示一个类或者接口
- PackageElement 表示一个包元素

可以通过 ElementKind.XXX 来判断元素的具体类型。

通过一个 map 来存放收集到的信息，ProxyInfo 为存放信息的集合和处理 elment 的地方，稍后再讲解。

```java
private Map<String, ProxyInfo> mProxyMap = new HashMap<>();
 public boolean process(Set<? extends TypeElement> set, RoundEnvironment roundEnvironment) {
        mProxyMap.clear();
        //拿到注解的元素
        Set<? extends Element> elements = roundEnvironment.getElementsAnnotatedWith(BindView.class);

        for (Element element : elements) {
            if (!checkAnnotationUseValid(element, BindView.class)) {
                return false;
            }
            //代表被注解的元素成员变量
            VariableElement variableElement = (VariableElement) element;
            //代表被注解的元素所在的class
            TypeElement typeElement = (TypeElement) variableElement.getEnclosingElement();
            //拿到class的完整路径
            String qualifiedName = typeElement.getQualifiedName().toString();
            //装载信息
            ProxyInfo info = mProxyMap.get(qualifiedName);
            if (info == null) {
                info = new ProxyInfo(mElementUtils, typeElement);
                mProxyMap.put(qualifiedName, info);
            }
            int id = variableElement.getAnnotation(BindView.class).value();
            info.injectVariables.put(id, variableElement);
        }
        ...
        return true;
    }
```

通过`getElementsAnnotatedWith`方法拿到注解的元素合集，然后循环遍历通过 element 获得相关的信息装载 ProxyInfo 。

#### 生成代理类

```java

    private void writeToFile() {
        for (String className : mProxyMap.keySet()) {
            ProxyInfo proxyInfo = mProxyMap.get(className);
            //生成成员变量的复制语句 view=findViewById(id)
            MethodSpec.Builder elementStatement = proxyInfo.markElementStatement();
            //构建 class
            TypeSpec typeSpec = TypeSpec.classBuilder(proxyInfo.typeElement.getSimpleName() + "_ViewBinding")
                    .addModifiers(Modifier.PUBLIC)
                    .addMethod(elementStatement.build())
                    .build();
            //将 class 文件放置在目标class同一个包下，解决访问性的问题
            String packageFullName = mElementUtils.getPackageOf(proxyInfo.typeElement).getQualifiedName().toString();
            JavaFile javaFile = JavaFile.builder(packageFullName, typeSpec).build();
            try {
                javaFile.writeTo(mFileUtils);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

```

这里我们主要通过 遍历所有的元素集来生成代理类。

通过`proxyInfo.markElementStatement()` 方法来生成具体的赋值语句然后打包成一个方法。

通过 `javapoet` 声明一个代理类，将方法放置在类中。

最后通过将代理类生成在和目标文件同一个包下，到这里就完成了所有的操作。

`markElementStatement()`的具体实现：

```java
public MethodSpec.Builder markElementStatement() {
        ParameterSpec.Builder paramsBuilder = ParameterSpec.builder(TypeName.get(typeElement.asType()), "target");
        MethodSpec.Builder methodBuilder = MethodSpec.constructorBuilder()
                .addModifiers(Modifier.PUBLIC)
                .addParameter(paramsBuilder.build());
        for (Integer id : injectVariables.keySet()) {
            VariableElement variableElement = injectVariables.get(id);
            //变量名称
            String variableName = variableElement.getSimpleName().toString();
            //变量的完整名称
            String canonicalName = variableElement.asType().toString();
            //在构造方法中添加赋值语句
            methodBuilder.addStatement("target.$L=($L) activity.findViewById($L)", variableName, canonicalName, id);
        }
        return methodBuilder;
    }
```

#### Api编写

注解处理完后，我们就需要 api 来调用这个代理类，将 View 通过代理类赋值。就像 `ButterKinfe.bind(target)`这样。

同样我们再声明一个 Android-module 来声明编写 api。api  的实现很简单，我们通过反射调用生成的代理类，将 Activity 当做参数传递进去即可。当然如果要实际应用肯定需要要考虑更多，例如缓存之类的，这里就只是简单的使用一下。

```Java
public class InjectHelper {

    public static void inject(Activity target) {
        String classFullName = target.getClass().getName() + "_ViewBinding";
        try {
            Class proxy = Class.forName(classFullName);
            Constructor constructor = proxy.getConstructor(target.getClass());
            constructor.newInstance(target);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}			
```

最后我们的 demo 依赖这三个库，通过使用@BindView 注解然后 biuld app.就可以在 build/gennerated/source/apt/debug/com.xxx/ 目录下看到我们生成的代理类了。

```java
public class MainActivity_ViewBinding {
  public MainActivity_ViewBinding(MainActivity activity) {
    activity.textView=(android.widget.TextView) activity.findViewById(2131165309);
  }
}
```

## 总结

通过这篇文章，整理的自定义注解和编译时注解框架所需要的常用知识点，它们都有广泛的应用场景，这里只是介绍最简单明了的，主要是为了了解基于编译时注解框架的原理和实现方式。如果有机会，自己根据场景设计使用编译时注解框架是最好不过的了。