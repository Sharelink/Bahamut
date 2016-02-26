
//打开字划入效果
window.onload = function(){
    $(".connect p").eq(0).animate({ "left": "0%" }, 600);
    $(".connect p").eq(1).animate({ "left": "0%" }, 400);
};
//jquery.validate表单验证
$(document).ready(function(){
    document.getElementById("privacy").onclick = function(){
    	controller.showPrivacy();
    };
    document.getElementById("login").onclick = function(){
        window.location.href = "login_" + lang + ".html";
        return false;
    }
    
	//注册表单验证
	$("#registerForm").validate({
		rules:{
		},
		//错误信息提示
		messages:{
		},

		//表单提交
		submitHandler:function(form){

			if(!testUsername(form.username.value)){
				controller.alert(localizableStrings.usernameFormatError);
				return
			}else if(!testPassword(form.password.value)){
				controller.alert(localizableStrings.passwordFormatError);
				return
			}
            var originPsw = form.password.value;
            var username = form.username.value;
            controller.registAccount(username,originPsw)
			
  		}
	});
});
