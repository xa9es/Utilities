-------
-------     notification lib made by hostilepair (pasted from every AI possible. ChatGPT. Bard. Gemini. Claude. Deepseek. Perplexity. ABCD.)
-------     0% human coding
-------

local Notifications
do
    local NotificationManager = {}
    NotificationManager.active_notifications = {}

------------------------------------------- looks configuration. if u want notifications to look or act differently then change these. 
    
    NotificationManager.Style = {
        MIN_WIDTH                   = 250,
        MIN_HEIGHT                  = 25,
        MAX_WIDTH                   = 500, 
        
        -- anims
        ENTER_DURATION              = 350,
        DISMISS_DURATION            = 400,
        BOUNCE_DURATION             = 180,
        BOUNCE_SCALE                = 0.95,
        SPRING_CONSTANT             = 300,
        DAMPING_FACTOR              = 40,
        
        -- warning colors
        WARNING_PULSE_TARGET_COLOR  = { r = 100, g = 50, b = 50 },
        PULSE_SPEED                 = 350,
    
        -- main colors /////////
        BG_COLOR                    = { r = 60, g = 56, b = 54 },
        BG_ALPHA                    = 235,
        OUTLINE_COLOR               = { r = 130, g = 125, b = 120 },
        OUTLINE_ALPHA               = 255,
        TITLE_COLOR                 = { r = 245, g = 245, b = 245 },
        TITLE_ALPHA                 = 255,
        BODY_COLOR                  = { r = 190, g = 190, b = 190 },
        BODY_ALPHA                  = 255,
        CLOSE_BUTTON_COLOR          = { r = 190, g = 190, b = 190 },
        CLOSE_BUTTON_ALPHA          = 255,
        TEXT_GLOW_COLOR             = { r = 255, g = 255, b = 255 },
        TEXT_GLOW_ALPHA             = 15,
        BORDER_GLOW_COLOR           = { r = 100, g = 95, b = 90 },
        GLOW_INTENSITY              = 60, 
        ROUNDNESS                   = 12,
        GLOW_LAYERS                 = 20,
        GLOW_SPREAD                 = 0.28,
        PADDING_X                   = 20,
        PADDING_Y                   = 15,
        LINE_SPACING                = 5,
        PADDING_BETWEEN_NOTIFICATIONS = 15,
    }


------------------------------------------- helper functions

    local function ease_out_cubic(t) return 1 - (1 - t) ^ 3 end
    local function lerp(a, b, t) return a + (b - a) * t end
    local function lerp_color(c1, c2, t) return Color3.fromRGB(lerp(c1.r, c2.r, t), lerp(c1.g, c2.g, t), lerp(c1.b, c2.b, t)) end

    local function render_smooth_glow(x, y, w, h, color_table, roundness, layers, spread, intensity, alpha_multiplier)
        local glow_color = Color3.fromRGB(color_table.r, color_table.g, color_table.b)
        
        if layers == 0 then return end
        local alpha_per_layer = intensity / layers

        for i = layers, 1, -1 do
            local current_spread = i * spread
            draw.RectFilled(x - current_spread, y - current_spread, w + (current_spread * 2), h + (current_spread * 2), glow_color, roundness + current_spread, alpha_per_layer * alpha_multiplier)
        end
    end

    local function render_soft_glow_text(text, x, y, main_color_table, main_alpha, glow_color_table, glow_alpha, alpha_multiplier)
        if not text or text == "" then return end

        local glow_color = Color3.fromRGB(glow_color_table.r, glow_color_table.g, glow_color_table.b)
        local main_color = Color3.fromRGB(main_color_table.r, main_color_table.g, main_color_table.b)
        local final_glow_alpha = glow_alpha * alpha_multiplier
        local final_main_alpha = main_alpha * alpha_multiplier

        -- glow
        draw.Text(text, x - 1, y - 1, glow_color, nil, final_glow_alpha); draw.Text(text, x, y - 1, glow_color, nil, final_glow_alpha); draw.Text(text, x + 1, y - 1, glow_color, nil, final_glow_alpha)
        draw.Text(text, x - 1, y,     glow_color, nil, final_glow_alpha);                                                              draw.Text(text, x + 1, y, glow_color, nil, final_glow_alpha)
        draw.Text(text, x - 1, y + 1, glow_color, nil, final_glow_alpha); draw.Text(text, x, y + 1, glow_color, nil, final_glow_alpha); draw.Text(text, x + 1, y + 1, glow_color, nil, final_glow_alpha)
        
        -- main
        draw.Text(text, x, y, main_color, nil, final_main_alpha)
    end
    
    local function wrap_text(text, max_width)
        if not text or text == "" then return {}, 0, 0 end

        local lines = {}
        local current_line = ""
        local max_line_width = 0
        local _, single_line_height = draw.GetTextSize("Tg")

        for word in string.gmatch(text, "%S+") do
            local test_line = (current_line == "") and word or (current_line .. " " .. word)
            local test_width, _ = draw.GetTextSize(test_line)

            if test_width > max_width and current_line ~= "" then
                table.insert(lines, current_line)
                local current_width, _ = draw.GetTextSize(current_line)
                max_line_width = math.max(max_line_width, current_width)
                current_line = word
            else
                current_line = test_line
            end
        end

        if current_line ~= "" then
            table.insert(lines, current_line)
            local current_width, _ = draw.GetTextSize(current_line)
            max_line_width = math.max(max_line_width, current_width)
        end

        local total_height = (#lines * single_line_height) + (math.max(0, #lines - 1) * NotificationManager.Style.LINE_SPACING)
        return lines, max_line_width, total_height
    end

------------------------------------------- the main logic

    function NotificationManager:draw_notification(data)
        local S = self.Style
        
        -- dimensions for text
        local title_w, title_h = draw.GetTextSize(data.title)
        local max_content_w = S.MAX_WIDTH - (S.PADDING_X * 2)
        local wrapped_body, body_w, body_h = wrap_text(data.body, max_content_w)
        
        local required_w = math.max(title_w, body_w) + (S.PADDING_X * 2)
        local required_h = S.PADDING_Y + title_h + S.LINE_SPACING + body_h + S.PADDING_Y
        data.w = math.min(S.MAX_WIDTH, math.max(S.MIN_WIDTH, required_w))
        data.h = math.max(S.MIN_HEIGHT, required_h)
        
        local x_offset, scale, alpha_multiplier = 0, 1.0, 1.0
        local bg_color = Color3.fromRGB(S.BG_COLOR.r, S.BG_COLOR.g, S.BG_COLOR.b)
        
        if data.type == "warning" then
            local pulse = (math.sin(utility.GetTickCount() / S.PULSE_SPEED) + 1) / 2
            bg_color = lerp_color(S.BG_COLOR, S.WARNING_PULSE_TARGET_COLOR, pulse)
        end
        
        -- anims based on what state they are
        local p = data.anim_progress
        if data.state == "entering" then
            x_offset = (1.0 - ease_out_cubic(p)) * 100
            alpha_multiplier = p
        elseif data.state == "bouncing" then
            scale = 1.0 - (4 * (p - (p * p))) * (1.0 - S.BOUNCE_SCALE)
        elseif data.state == "exiting" then
            local eased_p = ease_out_cubic(p)
            x_offset = eased_p * (data.w + 50)
            alpha_multiplier = 1.0 - p
        end
        
        -- final pos + size
        local final_w, final_h = data.w * scale, data.h * scale
        local final_x, final_y = data.x + x_offset + (data.w - final_w) / 2, data.current_y + (data.h - final_h) / 2
        
        render_smooth_glow(final_x, final_y, final_w, final_h, S.BORDER_GLOW_COLOR, S.ROUNDNESS * scale, S.GLOW_LAYERS, S.GLOW_SPREAD, S.GLOW_INTENSITY, alpha_multiplier)
        local outline_color = Color3.fromRGB(S.OUTLINE_COLOR.r, S.OUTLINE_COLOR.g, S.OUTLINE_COLOR.b)
        draw.Rect(final_x, final_y, final_w, final_h, outline_color, 1.0, S.ROUNDNESS * scale, S.OUTLINE_ALPHA * alpha_multiplier)
        draw.RectFilled(final_x + 1, final_y + 1, final_w - 2, final_h - 2, bg_color, (S.ROUNDNESS - 1) * scale, S.BG_ALPHA * alpha_multiplier)
        
        local content_x = final_x + (S.PADDING_X * scale)
        local current_y_text = final_y + (S.PADDING_Y * scale)
        render_soft_glow_text(data.title, content_x, current_y_text, S.TITLE_COLOR, S.TITLE_ALPHA, S.TEXT_GLOW_COLOR, S.TEXT_GLOW_ALPHA, alpha_multiplier)
        
        current_y_text = current_y_text + (title_h * scale) + (S.LINE_SPACING * scale)
        local _, line_h = draw.GetTextSize("Tg")
        for i, line in ipairs(wrapped_body) do
            render_soft_glow_text(line, content_x, current_y_text, S.BODY_COLOR, S.BODY_ALPHA, S.TEXT_GLOW_COLOR, S.TEXT_GLOW_ALPHA, alpha_multiplier)
            if i < #wrapped_body then
                current_y_text = current_y_text + (line_h * scale) + (S.LINE_SPACING * scale)
            end
        end
        
        local close_char = "×" -- im so cool for findnig this special character :)))
        local close_w, close_h = draw.GetTextSize(close_char)
        data.close_btn = { x = final_x + final_w - (close_w * scale) - (S.PADDING_X * scale), y = final_y + (S.PADDING_Y * scale), w = close_w * scale, h = close_h * scale }
        local close_color = Color3.fromRGB(S.CLOSE_BUTTON_COLOR.r, S.CLOSE_BUTTON_COLOR.g, S.CLOSE_BUTTON_COLOR.b)
        draw.TextOutlined(close_char, data.close_btn.x, data.close_btn.y, close_color, nil, S.CLOSE_BUTTON_ALPHA * alpha_multiplier)
    end

    function NotificationManager:update()
        local S = self.Style
        local current_time = utility.GetTickCount()
        local delta_time = utility.GetDeltaTime()
        local mouse_clicked = mouse.is_clicked("leftmouse")
        local mouse_pos = utility.GetMousePos()
        local cursor_x, cursor_y = mouse_pos[1], mouse_pos[2]

        for i = #self.active_notifications, 1, -1 do
            local notif = self.active_notifications[i]
            
            -- anim states
            if notif.state == "entering" then
                local elapsed = current_time - notif.anim_start_time
                notif.anim_progress = math.min(1.0, elapsed / S.ENTER_DURATION)
                if notif.anim_progress >= 1.0 then notif.state = "idle" end

            elseif notif.state == "idle" and notif.type == "timed" and (current_time - notif.creation_time) >= notif.duration then
                notif.state = "exiting"
                notif.anim_start_time = current_time
                notif.anim_progress = 0

            elseif notif.state == "bouncing" then
                local elapsed = current_time - notif.anim_start_time
                notif.anim_progress = math.min(1.0, elapsed / S.BOUNCE_DURATION)
                if notif.anim_progress >= 1.0 then
                    notif.state = "exiting"
                    notif.anim_start_time = current_time
                    notif.anim_progress = 0
                end

            elseif notif.state == "exiting" then
                local elapsed = current_time - notif.anim_start_time
                notif.anim_progress = math.min(1.0, elapsed / S.DISMISS_DURATION)
                if notif.anim_progress >= 1.0 then
                    table.remove(self.active_notifications, i)
                    goto continue
                end
            end
            
            -- y axis movement 
            if notif.state ~= "exiting" then
                local spring_force = (notif.target_y - notif.current_y) * S.SPRING_CONSTANT
                local damping_force = -notif.y_velocity * S.DAMPING_FACTOR
                local acceleration = spring_force + damping_force
                notif.y_velocity = notif.y_velocity + acceleration * delta_time
                notif.current_y = notif.current_y + notif.y_velocity * delta_time
            end

            -- click detection for close button
            if mouse_clicked and (notif.state == "idle" or notif.state == "entering") and notif.close_btn then
                if cursor_x >= notif.close_btn.x and cursor_x <= notif.close_btn.x + notif.close_btn.w and cursor_y >= notif.close_btn.y and cursor_y <= notif.close_btn.y + notif.close_btn.h then
                    notif.state = "bouncing"
                    notif.anim_start_time = current_time
                    notif.anim_progress = 0
                end
            end
            ::continue::
        end
    end

    function NotificationManager:paint()
        local screen_w, _ = cheat.getWindowSize()
        local base_x = screen_w - 50
        local stacking_y = 50
        self.stack_bottom_y = stacking_y

        -- Draw each active notification and calculate its stacked position
        for _, notif in ipairs(self.active_notifications) do
            notif.x = base_x - (notif.w or self.Style.MIN_WIDTH)
            if notif.state ~= "exiting" then
                notif.target_y = stacking_y
                stacking_y = stacking_y + (notif.h or self.Style.MIN_HEIGHT) + self.Style.PADDING_BETWEEN_NOTIFICATIONS
                self.stack_bottom_y = stacking_y
            end
            self:draw_notification(notif)
        end
    end

    -- =====================================================================================
    -- ||                                 API                                             ||
    -- =====================================================================================
    
    function NotificationManager:Show(options)
        options = options or {}
        local spawn_y = self.stack_bottom_y or 50

        local new_notif = {
            title           = options.title or "Notification",
            body            = options.body or "",
            type            = options.type or "normal", -- "normal", "timed", "warning" normal + warning are click to dismiss, and timed is self-explanatory.
            duration        = options.duration or 3000,
            creation_time   = utility.GetTickCount(),
            state           = "entering",
            anim_progress   = 0,
            anim_start_time = utility.GetTickCount(),
            current_y       = spawn_y,
            target_y        = spawn_y,
            y_velocity      = 0,
            w               = 0,
            h               = 0,
            close_btn       = nil,
        }
        table.insert(self.active_notifications, new_notif)
    end
    
    Notifications = NotificationManager
end

cheat.register("onUpdate", function()
    Notifications:update()
end)

cheat.register("onPaint", function()
    Notifications:paint()
end)

return Notifications
