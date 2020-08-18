# Carthage-Cache
随着模块化的设计，模块会越来越多，编译会越来越慢，为了解决编译慢的问题，基于二进制的编译提效策略将是现阶段比较好的方法。
常见的依赖管理工具Cocoapods和而Carthage都是很优秀，考虑后续的迭代问题，采用carthage制作二进制，然后再通过cocoapods管理依赖。
需要将carthage编译的framework发布到服务器，供cocoapods和carthage下载。

## 缓存支持平台

- [ ] gitlab(APIV4)


### gitlab
适用于没文件管理平台的团队，使用gitlab的自带的repo管理framework，工作流出如下：
1.一个公共的repo来分发和管理framework（公有、私有都可以）
2.通过**carthage build**生成framwork，然后通过carthage_cache push --repo=xxx.git xxxframework推送gitlab。carthage_cache内部会通过gitlab的api来管理repo

#### gitlab私有repo
在当前用户目录创建**carthage_cache.json**文件，因gitlab需要通过person-token来鉴权，请参考配置文件

```json
{
  "gitlab": {
    "sources": {
      "需要修改成真实的repo地址": {
        "PRIVATE-TOKEN": "参考https://docs.gitlab.com/ee/api/README.html#authentication生成"
      }
    }
  }
}
```



