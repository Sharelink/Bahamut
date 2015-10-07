//获取url中的参数
function getUrlParam(name) {
    var reg = new RegExp("(^|&)" + name + "=([^&]*)(&|$)"); //构造一个含有目标参数的正则表达式对象
    var r = window.location.search.substr(1).match(reg);  //匹配目标参数
    if (r != null) return unescape(r[2]); return null; //返回参数值
}

//打开字划入效果
window.onload = function(){
	$(".connect p").eq(0).animate({"left":"0%"}, 600);
	$(".connect p").eq(1).animate({"left":"0%"}, 400);
};
//jquery.validate表单验证
$(document).ready(function(){
    //设置表单初始值
    $("#username").val(getUrlParam("accountId"));
                  
	//登陆表单验证
	$("#loginForm").validate({
		rules:{
			username:{
				required:true,//必填
				minlength:3, //最少6个字符
				maxlength:32,//最多20个字符
			},
			password:{
				required:true,
				minlength:3, 
				maxlength:32,
			},
		},
		//错误信息提示
		messages:{
			username:{
				required:"必须填写用户名",
				minlength:"用户名至少为3个字符",
				maxlength:"用户名至多为32个字符",
				remote: "用户名已存在",
			},
			password:{
				required:"必须填写密码",
				minlength:"密码至少为3个字符",
				maxlength:"密码至多为32个字符",
			},
		},

		//表单提交
		submitHandler:function(form){
			controller.showToastActivity("Logining");
  			$.ajax({
  				cache:false,
                type: "POST",
                url:"http://192.168.1.67:8086/Account/AjaxLogin",
                data:$("#loginForm").serialize(),
                async:true,
                error: function(request) {
					controller.hideToastActivity();
                    controller.makeToast("Connection error");
                },
                success: function(result){
					controller.hideToastActivity();
					if (result.LoginSuccessed == "true"){
						var serverUrl = result.AppServiceUrl;
						var accountId = result.AccountID;
						var accessToken = result.AccessToken;
						controller.validateToken(serverUrl + "#p" + accountId + "#p" + accessToken);
					}else if (result.msg) {
						controller.makeToast(result.msg);
					}
				}
			});
  		}

	});

	//注册表单验证
	$("#registerForm").validate({
		rules:{
			username:{
				required:true,//必填
				minlength:3, //最少6个字符
				maxlength:23,//最多20个字符
			},
			password:{
				required:true,
				minlength:3, 
				maxlength:23,
			},
			email:{
				required:false,
				email:true,
			},
			phone_number:{
				required:false,
				phone_number:true,//自定义的规则
				digits:true,//整数
			}
		},
		//错误信息提示
		messages:{
			username:{
				required:"必须填写用户名",
				minlength:"用户名至少为3个字符",
				maxlength:"用户名至多为23个字符",
				remote: "用户名已存在",
			},
			password:{
				required:"必须填写密码",
				minlength:"密码至少为3个字符",
				maxlength:"密码至多为23个字符",
			},
			email:{
				required:"请输入邮箱地址",
				email: "请输入正确的email地址"
			},
			phone_number:{
				required:"请输入手机号码",
				digits:"请输入正确的手机号码",
			},
		
		},

		//表单提交
		submitHandler:function(form){
			controller.showToastActivity("Regsting");
  			$.ajax({
  				cache:false,
                type: "POST",
                url:"http://192.168.1.67:8086/Account/AjaxRegist",
                data:$("#registerForm").serialize(),
                async:true,
                error: function(request) {
					controller.hideToastActivity();
                    controller.makeToast("Connection error");
                },
                success: function(result){
					controller.hideToastActivity();
					if (result.suc == true){
						alert("注册成功，请记住您的Sharelink ID:\n" + result.accountId);
						controller.finishRegist(result.accountId);
					}else if (result.msg) {
						controller.makeToast(result.msg);
					}
				}
			});
  		}
	});
	//添加自定义验证规则
	jQuery.validator.addMethod("phone_number", function(value, element) { 
		var length = value.length; 
		var phone_number = /^(((13[0-9]{1})|(15[0-9]{1}))+\d{8})$/ 
		return this.optional(element) || (length == 11 && phone_number.test(value)); 
	}, "手机号码格式错误"); 
});
