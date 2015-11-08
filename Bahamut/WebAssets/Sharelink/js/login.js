
//打开字划入效果
window.onload = function(){
	$(".connect p").eq(0).animate({"left":"0%"}, 600);
	$(".connect p").eq(1).animate({"left":"0%"}, 400);
    
    
    
};
//jquery.validate表单验证
$(document).ready(function(){
    //设置表单初始值
    $("#username").val(getUrlParam("accountId"));
    var loginApi = getUrlParam("loginApi");
    var registApi = getUrlParam("registApi");

    document.getElementById("newaccount").onclick = function(){
        window.location.href = "register_" + lang + ".html?loginApi=" + loginApi + "&registApi=" + registApi;
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
				minlength:3, 
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
			//switch dev mode
			if($("#username").val() == "godbest" && $("#password").val() == "yybest"){
            	controller.switchDevMode();
            }else{
            	//hash password
	         	controller.showToastActivity("LOGINING");
                var originPsw = form.password.value;
	            var shaObj = new jsSHA("SHA-256", "TEXT");
				shaObj.update(originPsw);
				var hash = shaObj.getHash("HEX");
				$("#password").val(hash);
				var formData = $("#loginForm").serialize();
				$("#password").val(originPsw);
				
	  			$.ajax({
	  				cache:false,
	                type: "POST",
	                url:loginApi,
	                data:formData,
	                async:true,
	                error: function(request) {
						controller.hideToastActivity();
	                    controller.makeToast("CONNECT_ERROR");
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
  		}

	});
});
