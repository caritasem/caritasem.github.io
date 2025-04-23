---
layout: article
title:  "如何在Python中使用异步方式连接mysql"
date:   2025-04-23 11:00:07 +0800
categories: python
tags: 
    - Python
    - Mysql
    - Asynchronously
---

数据库请求是典型的 IO 密集型任务，因为它大部分时间都在等待数据库服务器的响应。因此，如果应用程序需要发起大量数据库请求，通过并发执行这些请求可以显著提升性能，在使用 FastAPI 进行 Web 开发时，我们经常需要在协程（即通过 async def 语句定义的函数）中发起数据库请求。本文记录了在不同场景下如何异步使用 SQLAlchemy

## 1. 安装所需依赖

```
conda create -n sql python=3.12
conda activate sql

pip install SQLAlchemy==2.0.40
pip install aiomysql==0.2.0
pip install cryptography==44.0.2
```
- `sqlalchemy`：SQLAlchemy 会与 `greenlet` 依赖一同安装，`greenlet` 是一个供 SQLAlchemy 实现异步操作的库。
- `aiomysql`：这是一个用于在 `asyncio` 框架下访问 MySQL 数据库的驱动程序，其底层使用了 `PyMySQL`。
- `cryptography`：SQLAlchemy 用它来进行身份验证。 


## 2. 创建异步连接
```
class Demo():
    def __init__(self):
        self.url = f"mysql+aiomysql://{dbconf.user}:{dbconf.passwd}@{dbconf.host}:{dbconf.port}/{dbconf.db}?charset=utf8mb4"

    async def connect(self):
        self.engine = create_async_engine(
            self.url,
            pool_size=10,
            max_overflow=5,
            echo=False,
            pool_pre_ping=True,
            connect_args={
                'connect_timeout': 1}
        )
        try:
            # check connection
            async with self.engine.connect() as conn:
                await conn.execute(text("select 1"))
        except Exception as e:
            raise

        self.AsyncSessionLocal = async_sessionmaker(
            autocommit=False, autoflush=False, bind=self.engine, expire_on_commit=False)

    async def fetch(self):
        logger.info("create mysql connection pool")
        await self.connect()
        return {'handle': self.get_session, "engine": self.engine}

    @asynccontextmanager
    async def get_session(self):
        async with self.AsyncSessionLocal() as session:
            try:
                yield session
            except Exception:
                logger.exception("Session rollback because of exception")
                await session.rollback()
                raise
            finally:
                await session.close()

    async def callback(self):
        # print(__file__, self.engine)
        logger.info("dispose mysql connection")
        await self.engine.dispose()
```

## 3. 执行查询操作
```
demo = Demo()
handle, _ = demo.fetch()

async def test_select():
    try:
        async with handle() as session:
            sql = """SELECT * from demo_table
                    WHERE
                        column_a = :column_a
                """
            res = await session.execute(text(sql), {"column_a": 123})

            applist_data = pd.DataFrame(
                res.fetchall(), columns=res.keys()).astype({'first_install_time': str, 'last_update_time': str}).to_dict(orient='records')

    except Exception as e:
        logger.error(traceback.format_exc())
        raise

asyncio.run(test_select())

```

