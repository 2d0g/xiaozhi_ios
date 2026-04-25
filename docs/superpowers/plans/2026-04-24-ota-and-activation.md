# 小智 AI iOS OTA 激活实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 实现设备通过 HTTPS 向 `xiaozhi.me` 进行 OTA 注册、获取激活码并检测激活状态的功能。

**Architecture:** 
- `NetworkManager`: 基于 `URLSession` 的单例，处理 JSON 请求及基础错误。
- `OTAContext`: 数据模型，存储服务器返回的 `auth_token`, `websocket_url`, `mqtt` 配置等。
- `OTAService`: 业务逻辑类，负责具体的请求组合。

**Tech Stack:** Swift 6 (Concurrency/Async-Await), URLSession, Codable.

---

### Task 4: 实现 NetworkManager 与基础网络层

**Files:**
- Create: `xiaozhi/Services/Network/NetworkManager.swift`
- Test: `xiaozhiTests/NetworkManagerTests.swift`

- [ ] **Step 1: 编写测试验证基础 POST 请求**
- [ ] **Step 2: 实现 NetworkManager (Async/Await)**

---

### Task 5: 实现 OTA 数据模型与握手协议

**Files:**
- Create: `xiaozhi/Models/OTAContext.swift`
- Create: `xiaozhi/Services/Network/OTAService.swift`
- Test: `xiaozhiTests/OTAServiceTests.swift`

- [ ] **Step 1: 定义 OTARequest (包含 SN, HMAC 等字段)**
- [ ] **Step 2: 定义 OTAResponse (解析服务器返回的 JSON)**
- [ ] **Step 3: 实现 OTAService.handshake() 获取激活码**

---

### Task 6: 激活状态检测逻辑

- [ ] **Step 1: 实现 OTAService.checkStatus()**
- [ ] **Step 2: 在 IdentityTests 中添加集成测试验证流程**
