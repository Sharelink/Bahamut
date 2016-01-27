//获取url中的参数
function getUrlParam(name) {
    var reg = new RegExp("(^|&)" + name + "=([^&]*)(&|$)"); //构造一个含有目标参数的正则表达式对象
    var r = window.location.search.substr(1).match(reg);  //匹配目标参数
    if (r != null) return unescape(r[2]); return null; //返回参数值
};

function testUsername(username){
    var usernameRegex = new RegExp('^[_a-zA-Z0-9\u4e00-\u9fa5]{2,23}$');
	var res = usernameRegex.test(username);
    return res;
};

function testPassword(password){
    var pswRegex = new RegExp('^[A-Za-z0-9_\@\!\#\$\%\^\&\*\.\~]{6,23}$');
    var res = pswRegex.test(password);
    return res;
};