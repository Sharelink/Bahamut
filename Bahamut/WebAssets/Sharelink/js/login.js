
//打开字划入效果
window.onload = function(){
    $(".connect p").eq(0).animate({ "left": "0%" }, 600);
    $(".connect p").eq(1).animate({ "left": "0%" }, 400);
};
//jquery.validate表单验证
$(document).ready(function(){
    //设置表单初始值
    $("#username").val(getUrlParam("accountId"));
    document.getElementById("newaccount").onclick = function(){
        window.location.href = "register_" + lang + ".html";
        return false;
    }
    
	//登陆表单验证
	$("#loginForm").validate({
		rules:{
			username:{
				required:true,//必填
				minlength:2, //最少2个字符
				maxlength:23,//最多23个字符
			},
			password:{
				required:true,
				minlength:6, 
				maxlength:23,
			}
		},
		//错误信息提示
		messages:{
			username:{
				required:localizableStrings.requireUsername,
				minlength:localizableStrings.usernameMinLength,
				maxlength:localizableStrings.usernameMaxLength
			},
			password:{
				required:localizableStrings.requirePassword,
				minlength:localizableStrings.passwordMinLength,
				maxlength:localizableStrings.passwordMaxLength,
			}
		},

		//表单提交
		submitHandler:function(form){
            var originPsw = form.password.value;
            var username = form.username.value;
            controller.loginAccount(username,originPsw);
  		}

	});
});
