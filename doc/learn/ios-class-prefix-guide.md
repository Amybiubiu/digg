# iOS 类名前缀使用指南

## 对话背景
作为前端工程师转入iOS开发，对为什么iOS项目需要类名前缀（如SL）存在疑问。

## 核心问题
为什么iOS需要类名前缀而前端不需要？

## 关键差异

### iOS (Objective-C) 的问题
- **全局命名空间**：所有类都在同一个符号表中
- **编译时链接**：类名成为二进制符号的一部分
- **历史原因**：1980年代设计，没有现代模块概念

### 前端 (JavaScript) 的优势
- **模块系统**：ES6模块有独立作用域
- **运行时加载**：通过import明确指定来源
- **命名空间隔离**：`import { User as MyUser } from './module'`

## 实际影响

### 没有前缀的风险
1. **与系统框架冲突**：`ViewController` vs `UIViewController`
2. **第三方库冲突**：不同库可能有相同的`NetworkManager`
3. **未来冲突**：Apple新增系统类可能冲突

### 本项目示例
项目中使用"SL"前缀：
- `SLHomePageViewController`
- `SLProfileViewController`
- `SLColorManager`
- `SLUser`

## 最佳实践
1. 使用3字母前缀（Apple推荐）
2. 保持全项目一致性
3. 大公司可以为不同模块使用不同前缀

## 现代改进
- Objective-C模块系统（部分解决）
- Swift有命名空间概念
- 但与Objective-C混编时仍需考虑前缀

## 总结
类名前缀是iOS开发的重要实践，用于避免命名冲突和提高代码可维护性。这是从全局命名空间的历史技术限制中发展出的解决方案。