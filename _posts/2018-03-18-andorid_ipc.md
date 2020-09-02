---
layout: post
title: "Android IPC 机制"
subtitle: "Android 艺术开发探索笔记"
date: 2018-03-18 20:55:00
author: "rank"
header-img: "img/post-bg-android.jpg"
catalog: true
tags:
  - Android
  - Note
---



IPC 是 Inter-Process Communication 的缩写，含义为进程间通信或跨进程通信，是指两个进程之间进行数据交换的过程。那么什么是进程？什么是线程？按照操作系统的概念，线程是 CPU 调度的最小单元，同时线程是一种有限的系统资源。二进程一般指一个执行单元，在 PC 和移动设备上指一个程序或者应用。一个进程可以包含多个线程，也可以只有一个线程即主线程，在Android 也叫 UI 线程。

### 为什么需要多进程通信，使用场景

前面也有说在操作系统中一个进程对应的指一个程序或者应用，当两个应用需要数据交互的时候就必须要采取夸进程的通信方式来获取所需要的数据。**在 Android 中每一个应用或进程都分配了一个独立的虚拟机，不同的虚拟机在内存分配上有不同的地址空间，这会导致不同虚拟机访问同一个类会产生多份副本。这时候通过内存来共享数据，都会共享失败**，不仅如此还会造成很多问题，例如：

1. 静态成员和单例模式完全失效
2. 线程同步机制完全失效
3. SharedPreferences 的可靠性下降
4. Application 会多次创建

所以任何一个操作系统都需要相应的 IPC 机制，比如 Windows 上可以通过剪贴板、管道和邮槽等来进行进程间通信；Linux 上可以通过命名管道、共享内容、信号量等来进行进程通信。对于 Android来说，它是一种基于 Linux 内核的移动操作系统，但它有自己的进程通信方式 Binder，除此之外还支持 Socket。

### Android 中的多进程模式

#### 开启多进程

在一个应用开启多进程只有一种方法，那就是给四大组件在 AndroidMenifest 中指定 android:process 属性，除此之外没有其他方法。还有一种非常规的多进程方法，那就是通过 JNI 在native 层去 fork 一个新的进程，这里不做阐述。

```java
  <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <activity
            android:name=".SecondActivity"
            android:process=":remote" />
        <activity
            android:name=".ThirdActivity"
            android:process="com.czj.adapter.remote" />
```

通过 process 属性值指定其运行的进程，假设当前应用的进程为 `com.czj.adapte` 那么当 SecondActivity 启动时 系统会为它创建一个新的进程，名为`com.czj.adpater:remote` ，当ThirdActiivty 启动时候系统也会为它新建一个进程，名为`com.czj.adpater.remote`。新建的两个进程其实是有区别的，" : " 的含义是指要在当前的进程名前面附加上当前的包名，这是一种简写的方法，对于 SecondActivity 它完整的进程是 `com.czj.adpate:remote` 它属于当前应用的私有进程，而不适用 “ ：” 开头的属于全局进程，其他应用通过 ShareUID 方式可以和它跑在同一个进程中。

Android 系统为每个应用分配了一个唯一的 UID，具有相同 UID 应用才能共享数据。这里要说明的是，两个应用只有拥有相同的ShareUID并且签名相同才可以跑在统一进程。在这种情况下它们可以互相访问对方的私有数据，比如 data 目录、组件信息等，不管它们是否泡在同一个进程中。

### IPC基础概念介绍

#### Binder

> 直观来讲，Binder 是 Android 中的一个类，它实现了 IBinder 接口。从 IPC 角度来讲，Binder 是 Android 系统的一种夸进程通信方式，BInder 还可以理解为一种虚拟的物理设备，它的设备驱动是 `/dev/binder`，该通信方式在 Linux 中没有；从 Android Framework 层角度来说，Binder 是 ServiceManager 连接各种 Manger (ActivityMnager、WindowManger，等等)和相应 ManagerService 的桥梁；从 Android 应用层来说，Binder 是客户端和服务端进行通信的媒介，当 bindService 的时候，服务端会返回一个包含了服务端业务调用的 Binder 对象，通过这个 Binder 对象，客户端就可以获得服务端提供的服务或者数据，这里的服务包括普通服务和机遇 AIDL 的服务。

#### Android 中的 IPC 方式

##### 使用Bundle

Activity、Service、Receiver 都是支持在 Intent 中传递 Bundle 数据的，由于 Bundle 时间了 Parcelable 接口，所以它可以方便地在不同的进程间传输。除了直接传递数据这种经典的使用场景，它还有一种特殊的使用场景。比如 A 进程在进行一个计算，计算完成后它要启动 B 进程的一个组件并把计算结果传递给 B 进程，并且遗憾的是这个计算结果不支持放入 Bundle 中，因此无法通过 Intent 来传输，这个时候使用 其他 IPC 就略显复杂。我们可以考虑将通过 Intent 启动 B 进程的一个 Service 组件，让 Service 在后台进行计算，计算完毕再启动 B 进程真正想要启动的目标组件，由于 Service 也运行在 B 进程中，所以目标组件就可以直接获取计算结果，这样一来就轻松解决了夸进程的问题。

#### 使用文件共享

共享文件也是一种不错的进程间通信，两个进程通过读/写同一个文件来交换数据。通过文件共享数据对文件格式是没有具体要求的，比如可以是文本共享、也是是 XML 只要双方约定数据格式即可。通过文件共享的方式也是有局限性的，比如并发读/写的问题，如果有并发的情况，那么我们读的内容可不能不是最新的，如果是并发写的话就更严重了。文件共享方式比较适合在对同步数据要求不高的进程间通信，并且妥善处理并发/读写的问题。

系统的 SharedPreferences 是 Android 提供的轻量级存储方案，它通过键值对的方式来存储数据，在底层上使用 xml 文件来保存。从本质上 SharedPreferences 也是文件的一种，但是由于系统对它的读/写做了一定的缓存策略，即在内存中会有一份 SharedPreferences 文件的缓存，因此在多进程模式下，系统对它的读写就变得很不可靠，当面对高并发的读/写访问，SharedPreferences 有很大几率丢失数据。

#### 使用 Messenger

Messenger 可以在不同进程传递 Message 对象，它是一种基于 AIDL 的轻量级 IPC 方案，对 AIDL 做了封装从而使我们可以更简便地进行进程间通信。且由于它一次只处理一种请求，因此服务端我们不用考虑线程同步的问题，这是因为在服务端中不存在并发执行的情况。

#### 使用AIDL

Messeneger 是以串行的方式来处理客户端发送的消息，如果大量的消息同时发送到到服务端，而服务端只能一个一个处理，那么用 Messenger 就不大合适了。同时，Messenger 的作用主要是为了传递消息，很多时候我们可能需要夸进程的调用服务端的方法，这种情况 Messenger 就无法做到了，但是我们可以使用 AIDL 来实现。

###### 创建 AIDL 

```Java
//创建 AIDL 文件Build后生成相应的类
// AIDL 支持 基本类型和 String、CharSequence、List、Map、Parcelable、AIDL
//当我们使用Parcelable时，我们要单独创建一个同名使用 parcelable 声明。
//Book.aidl
package com.example.nutcracker.myapplication;
parcelable Book;
//IBookManager.aidl
package com.example.nutcracker.myapplication;

import com.example.nutcracker.myapplication.Book;
interface IBookManger{
    List<Book> getBook();
    void addBook(Book book);
}
```

###### 服务端实现

```kotlin
public class AIDLService extends Service {

    private List<Book> bookList = new ArrayList<>();

    private IBookManager.Stub mBookManager = new IBookManager.Stub() {
        @Override
        public List<Book> getBookList() throws RemoteException {
            Log.i("service", "读取书籍");
            return bookList;
        }

        @Override
        public void addBook(Book book) throws RemoteException {
            Log.i("service", "添加书籍");
            bookList.add(book);
        }
    };

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return mBookManager;
    }
}
```

###### 客户端实现

```kotlin
//我们实现了一个定时向服务端添加书籍并查询书籍的组件
class ThirdActivity : AppCompatActivity() {

    lateinit var promptView: TextView


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_third)
        promptView = findViewById(R.id.textView2)
        val intent = Intent(this, AIDLService::class.java)
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    private val handle: Handler = @SuppressLint("HandlerLeak")
    object : Handler() {
        override fun handleMessage(msg: Message?) {
            super.handleMessage(msg)
            val book = manager.bookList.last()
            promptView.text = book.bookName
        }
    }
    var sum: Int = 0

    inner class MyThread : Runnable {
        override fun run() {
            while (true) {
                try {
                    manager.addBook(Book(1, "book$sum"))
                    sum++
                    Thread.sleep(1000)// 线程暂停1秒
                    val message = Message()
                    message.what = 1
                    handle.sendMessage(message)// 发送消息
                } catch (e: InterruptedException) {
                    e.printStackTrace()
                }

            }
        }
    }

    private var isConnection = false
    private lateinit var manager: IBookManager

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(p0: ComponentName?, p1: IBinder?) {
            manager = IBookManager.Stub.asInterface(p1)
            isConnection = true
            Log.i("client", " 连接上客户端")
            Thread(MyThread()).start()
        }

        override fun onServiceDisconnected(p0: ComponentName?) {
            isConnection = false
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unbindService(serviceConnection)
    }
}
```

#### 使用ContentProvider

ContentProvider 是 Android 中提供的专门用于不同应用之间共享数据的方式，从这一点来看，它天生就适合进程间通信。和 Messenger 一样，ContentProvider 的底层实现同样为 Binder。

###### 创建数据源

我们先创建一个数据库为ContentProvider提供数据

```kotlin
class DbOpenHelper(context: Context) : SQLiteOpenHelper(context, DB_NAME, null, DB_VERSION) {

    companion object {
        const val DB_VERSION = 1
        const val DB_NAME = "book_provider"
        public const val BOOK_TABLE_NAME = "book"
        public const val USER_TABLE_NAME = "user"

        const val CREATE_BOOK_TABLE = "CREATE TABLE  IF NOT EXISTS $BOOK_TABLE_NAME (_id INTEGER PRIMARY KEY,name TEXT)"
        const val CREATE_USER_TABLE = "CREATE TABLE  IF NOT EXISTS $USER_TABLE_NAME (_id INTEGER PRIMARY KEY,name TEXT,sex INT)"
    }

    override fun onCreate(db: SQLiteDatabase?) {
        db?.execSQL(CREATE_BOOK_TABLE)
        db?.execSQL(CREATE_USER_TABLE)

    }

    override fun onUpgrade(p0: SQLiteDatabase?, p1: Int, p2: Int) {
    }

}
```



###### 创建一个 ContentProvider

> 创建一个自定义的ContentProvider 只需要集成 ContentProvider 并实现六个抽象方法即可：onCreate、query、update、insert、delte、和  getType。这六个抽象方法都很好理解，onCreate 代表 ContentProvider 的创建，一般来说我们要做一些初始化的工作；getType 用来返回一个 Uri 请求所对应的 MIME 类型（媒体类型），比如图片、视频等，如果我们不关注这个类型可以直接返回 null 或 `*/*` ;剩下的四个方法对应 CRUD 操作，即实现对数据表的增删改查工作。根据 Binder 的工作原理，我们知道这六个方法均在 ContentProvider 的进程中，除了 onCreate 由系统回调并运行在主线程中，其他五个方法均由外界回调并运行在 Binder 线程池中。

我们来自定义一个 ContentProvider 并使用之前定义的DbOpenHelper 来作为操作的数据

```kotlin
class BookProvider : ContentProvider() {

    companion object {
        private const val TAG: String = "BookProvider"
        private const val AUTHORITIES = "com.example.nutcracker.myapplication.BookProvider"
        val BOOK_CONTENT_URI = Uri.parse("content://$AUTHORITIES/book")
        private const val BOOK_URI_CODE = 0
        val USER_CONTENT_URI = Uri.parse("content://$AUTHORITIES/user")
        private const val USER_URI_CODE = 1
        private val uriMather = UriMatcher(UriMatcher.NO_MATCH)
    }

    init {
        uriMather.addURI(AUTHORITIES, "book", BOOK_URI_CODE)
        uriMather.addURI(AUTHORITIES, "user", USER_URI_CODE)
    }

    lateinit var db: SQLiteDatabase


    override fun onCreate(): Boolean {
        Log.i(TAG, "onCreate,current thread:${Thread.currentThread()}")
        val openHelper = DbOpenHelper(context)
        db = openHelper.writableDatabase
        db.execSQL("delete from " + DbOpenHelper.BOOK_TABLE_NAME)
        db.execSQL("delete from " + DbOpenHelper.USER_TABLE_NAME)
        db.execSQL("insert into book values(3,'android');")
        db.execSQL("insert into book values(4,'iOS');")
        db.execSQL("insert into book values(5,'html');")
        db.execSQL("insert into user values(1,'jon',11);")
        return false
    }

    override fun query(uri: Uri, strings: Array<String>?, s: String?, strings1: Array<String>?, s1: String?): Cursor? {
        Log.i(TAG, "query,current thread:${Thread.currentThread()}")
        val tableName: String = getTableName(uri)
        return db.query(tableName, strings, s, strings1, null, null, s1, null)
    }

    override fun getType(uri: Uri): String? {
        return null
    }

    override fun insert(uri: Uri, contentValues: ContentValues?): Uri? {
        val tableName: String = getTableName(uri)
        db.insert(tableName, null, contentValues)
        context.contentResolver.notifyChange(uri, null)
        return uri
    }

    override fun delete(uri: Uri, s: String?, strings: Array<String>?): Int {
        val count = db.delete(getTableName(uri), s, strings)
        if (count > 0) {
            context.contentResolver.notifyChange(uri, null)
        }
        return count
    }

    override fun update(uri: Uri, contentValues: ContentValues?, s: String?, strings: Array<String>?): Int {
        val row = db.update(getTableName(uri), contentValues, s, strings)
        if (row > 0) {
            context.contentResolver.notifyChange(uri, null)
        }
        return row
    }

    private fun getTableName(uri: Uri): String {
        return when (uriMather.match(uri)) {
            BOOK_URI_CODE -> DbOpenHelper.BOOK_TABLE_NAME
            USER_URI_CODE -> DbOpenHelper.USER_TABLE_NAME
            else -> throw IllegalAccessException("Unsupported URI:$uri")
        }
    }
}

```

然后在清单文件申明它

```xml
       <provider
            android:name=".BookProvider"
       android:authorities="com.example.nutcracker.myapplication.BookProvider"
            android:permission="com.example.provider"
            android:process=":provider"
            />
```

其中 authorities 是Content-Provider 的唯一标示，通过这个属性外部应用就可以访问我们的 ContentProvider ，所以这个值必须是唯一的。为了演示进程间通信，我们让 BookProvider 运行在独立的进程并给它添加了权限，这样如果外部应用想访问它就必须申明对应的权限（这里指“"com.example.provider”）,否则外部应用就会异常终止。

###### 最后我们在Activity中测试使用我们的ContentProvider

```kotlin
class SecondActivity : AppCompatActivity() {

    companion object {
        const val TAG = "Application Provider"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_second)

        val values = ContentValues()
        values.put("_id", 6)
        values.put("name", "编程之美")
        contentResolver.insert(BookProvider.BOOK_CONTENT_URI, values)

        val cursor = contentResolver.query(BookProvider.BOOK_CONTENT_URI, arrayOf("_id", "name"), null, null, null)
        while (cursor.moveToNext()) {
            Log.i(TAG, "id:${cursor.getInt(0)} name :${cursor.getString(1)}")
        }
        cursor.close()
    }
}

----------------- 输出
03-18 22:54:42.415 1935-1935/com.example.nutcracker.myapplication:remote I/Application Provider: id:3 name :android
03-18 22:54:42.415 1935-1935/com.example.nutcracker.myapplication:remote I/Application Provider: id:4 name :iOS
03-18 22:54:42.415 1935-1935/com.example.nutcracker.myapplication:remote I/Application Provider: id:5 name :html
03-18 22:54:42.415 1935-1935/com.example.nutcracker.myapplication:remote I/Application Provider: id:6 name :编程之美
```

#### 使用Socket

我们也开始使用 Socket 来进行夸进程通信，除了使用 TCP  还可以使用 UDP 套接字。在性能上 UDP 具有更好的效率，其缺点是不保证数据一定能够正确传输，尤其是网络堵塞的情况下。

#### Binder 连接池



#### 选择合适的 IPC 方式

|      名称       |                             优点                             |                             缺点                             |                           适用场景                           |
| :-------------: | :----------------------------------------------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: |
|     Bundle      |                           简单易用                           |                  只能传输 Bundle 支持的数据                  |                     四大组件间的进程通信                     |
|    文件共享     |                           简单易用                           |        不适合高并发场景，并且无法做到进程间的即时通信        |        无并发访问情况，交换简单的数据实时性不高的场景        |
|      AIDL       |          功能强大，支持一对多并发通信，支持实时通信          |                使用稍复杂，需要处理好线程同步                |                  一对多通信并且有 RPC 需求                   |
|    Messenger    |          功能一般，支持一对多串行通信，支持实时通信          | 不能很好的处理高并发场景，不支持 RPC，数据通过 Message 传输，因此只支持 Bundle 支持的数据类型 | 低并发的一对多即使通信，无 RPC需求，或者无需返回结果的 PRC 需求 |
| ContentProvider | 在数据源访问功能强大，支持一对多并发数据共享，可通过 call 方法扩展其他操作 |    可以理解为，受约束的 AIDL，主要提供数据源的 CURD 操作     |                   一对多的进程间的数据共享                   |
|     Socket      |   功能强大，可以通过网络传输套接字，支持一对多并发实时通信   |            实现细节稍微有点繁琐，不支持直接的RPC             |                         网络数据交换                         |

