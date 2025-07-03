gg.setVisible(false);

-- タイムゾーン取得 -> baset
local t = os.time();
baset = os.difftime(t, os.time(os.date("!*t", t)));
baset = ("%d"):format(baset);

-- ベース値作成 -> basex
gg.clearResults();
local fs = gg.getRangesList("split_config.arm64_v8a.apk:bss");
gg.setRanges(fs[1] and -2080896 or 48);
gg.searchNumber(baset, 4, false, 536870912, 0, -1, 1);
local p = gg.getResults(1)[1].address;
for i = 0, 3 do
    local s = gg.getValues({{
        address = p + i, 
        flags = 1
    }})[1].value;
    basex = (basex or "h ")..(" %x"):format(s < 0 and 256 + s or s);
end

-- ベースアドレス取得 -> base
gg.clearResults();
gg.searchNumber(basex, 1, false, 536870912, fs[1] and fs[1].start or 0, fs[1] and fs[1].start +0xffff or -1);
gg.refineNumber(gg.getResults(1)[1].value, 1);
local res = gg.getResults(gg.getResultsCount());
for i = 1, #res do
    if not res[i+2] then
        base = res[i].address;
        break;
    end
    local cash = res[i+2].address-res[i+1].address;
    if cash > 0x3000 and cash < 0x4fff and (function()
        gg.clearResults();
        gg.searchNumber(("-256~255;"):rep(2)..("-257~~256;"):rep(2).."-256~255;-256~255::21", 4, false, 2^29, base, base +0x120);
        return gg.getResultsCount() == 6;
    end) then
        base = res[i].address;
        break;
    end
end

if not base then
    gg.alert("数値の初期設定に失敗しました。\nアプリを再起動してください");
    gg.setVisible(true);
    os.exit();
end

-- メニュー項目
local menu = {
    "猫缶 [ON]", 
    "猫缶の変更値を入力", 
    "XP [ON]", 
    "XPの変更値を入力",
    "にゃんこチケット [ON]",  
    "にゃんこチケットの変更値を入力", 
    "レアチケット [ON]", 
    "レアチケットの変更値を入力", 
    "即勝利", 
    "ステージ開放", 
    "全キャラ開放", 
    "エラキャラ削除", 
    "終了"
};

-- main code
function main()
    local mp = gg.prompt(menu, {
        [2] = 58000, 
        [4] = 777777777, 
        [6] = 200, 
        [8] = 200
    }, {
        [1] = "checkbox", 
        [3] = "checkbox", 
        [5] = "checkbox", 
        [7] = "checkbox", 
        [9] = "checkbox", 
        [10] = "checkbox", 
        [11] = "checkbox", 
        [12] = "checkbox", 
        [13] = "checkbox", 
    });
    if not mp then return;end
    for i = 1, #menu-1 do
        xpcall(function()
            if mp[i] == true then _ENV["p"..i](mp[i+1]);end
        end, function(e) -- エラー処理
            gg.alert(menu[i].."でエラーが発生しました。\n実行をスキップします。");
            print(menu[i]..":", e.."\n");
        end);
    end
    if mp[#menu] then owari();end
end

function edit(offs, val, name, bool)
    gg[bool and "addListItems" or "setValues"]({{
        address = base + offs, 
        freeze = true, 
        flags = 4, 
        name = name, 
        value = val
    }, {
        address = base + offs +0x4, 
        freeze = true, 
        flags = 4, 
        name = name.."0", 
        value = 0
    }});
end

function p1(v)
    edit(-0x118, v, "猫缶", true);
    gg.toast("猫缶成功");
end

function p3(v)
    edit(0x40, v, "XP", true);
    gg.toast("XP成功");
end

function p5(v)
    edit(0x2f3384, v, "にゃんこチケット", true);
    gg.toast("にゃんチケ成功");
end

function p7(v)
    edit(0x2f338c, v, "レアチケット", true);
    gg.toast("レア成功");
end

function p9()
    gg.clearResults();
    gg.searchNumber("3200;4400;1~2147483647::29", 4, false, 2^29, base, base+0xffffff);
    if gg.getResultsCount() < 4 then return gg.alert("試合中に実行してください。");end
    local res = gg.getResults(1, gg.getResultsCount()-1);
    gg.addListItems((function()
        res[1].freeze = true;
        res[1].value = 0;
        return res;
    end)());
    gg.toast("即勝利成功", true);
end

function p10()
    gg.clearResults();
    gg.searchNumber("0~~0", 4, false, 2^29, base +0x69c, base +0xee4);
    gg.getResults(11);
    gg.editAll(("304;"):rep(10).."256", 4);
    gg.getResults(520, 11);
    gg.editAll("257"..(";257"):rep(47)..(";256"):rep(4), 4);
    gg.toast("ステ開放成功");
end

function p11(v)
    gg.clearResults();
    gg.searchNumber("-257~~256", 4, false, 2^29, base +0x3aa38, base + 0x3b6fc);
    local res = gg.getResults(gg.getResultsCount() -1);
    gg.editAll(res[1].value, 4);
    gg.toast("全キャラ成功");
end

function p12()
    local err = {156,183,286,321,340,354,433,434,466,493,498,499,500,501,674,741,742,743,744,745,746,789,811,812,813,814,815,816,817};
    local editval = gg.getValues({{address = base +0x3b6fc, flags = 4}})[1].value;
    for _, n in ipairs(err) do
        gg.setValues({{
            address = base +0x3aa34 +n *0x4, 
            flags = 4, 
            value = editval
        }});
    end
    gg.toast("エラキャラ成功");
end

function owari()
    print("Script制作: Rento");
    gg.setVisible(true);
    os.exit();
end

gg.setVisible(true);
while true do
    if gg.isVisible() then
        gg.setVisible(false);
        main();
    end
end