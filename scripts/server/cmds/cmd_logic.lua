--cmd_logic.lua

-- 登录帐号命令处理
function cmd_login(agent, map)
    LOGIN_D.login(agent, map)
end

--逻辑服收到新用户登陆消息
function new_client_init(agent, port, data, ext)
    --端口区分本地端口
    port = port + 0x10000

    --断线重连
    local old_agent = find_agent_by_port(port)
    if old_agent then
        old_agent:connection_lost(true)
    end
    local client_agent = clone_object(AGENT_CLASS);
    -- 设置端口与 agent 的映射关系
    client_agent:set_all_port_no(port, agent:get_port_no())
    client_agent:set_client_ip(ext["client_ip"])
    client_agent:set_server_type(SERVER_TYPE_CLIENT)
end

--获取用户列表
function cmd_user_list(account)
    ACCOUNT_D.get_user_list(account)
end

function cmd_create_user(account, info)
    ACCOUNT_D.request_create_user(account, info)
end

function cmd_select_user(account, rid)
    ACCOUNT_D.request_select_user(account, rid)
end

function cmd_common_op(user, info)
    if info.oper == "add" then
        user:add_attrib(info.field, info.amount)
    elseif info.oper == "cost" then
        user:cost_attrib(info.field, info.amount)
    elseif info.oper == "add_item" then
        BONUS_D.do_user_bonus(user, {property = { {class_id = info.class_id, amount = info.amount} }}, BONUS_TYPE_SHOW, BONUS_TYPE_SHOW)
    end
end

function cmd_sale_object(user, info)
    local rid, amount = info.rid, info.amount
    local object = find_object_by_rid(rid)
    if not object or get_ob_rid(user) ~= object:query("owner") then
        return user:send_message(MSG_SALE_OBJECT, {ret = -1, err_msg = "物品rid有误"})
    end

    if object:query("sell_price") == 0 then
        return user:send_message(MSG_SALE_OBJECT, {ret = -1, err_msg = "该物品不可出售"})
    end

    local sale_amount = math.min(info.amount, object:query("amount"))
    user:add_attrib("gold", sale_amount * object:query("sell_price"))
    object:cost_amount(sale_amount)
    return user:send_message(MSG_SALE_OBJECT, {ret = 0})
end