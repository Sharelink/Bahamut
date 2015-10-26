
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
        window.location.href = "register.html?loginApi=" + loginApi + "&registApi=" + registApi;
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
				required:"必须填写用户名",
				minlength:"用户名至少为2个字符",
				maxlength:"用户名至多为23个字符",
				remote: "用户名已存在",
			},
			password:{
				required:"必须填写密码",
				minlength:"密码至少为3个字符",
				maxlength:"密码至多为23个字符",
			}
		},

		//表单提交
		submitHandler:function(form){
			//switch dev mode
			if($("#username").val() == "bahamut-sl" && $("#password").val() == "sldebug"){
            	controller.switchDevMode();
            }else{
            	//hash password
	         	controller.showToastActivity("Logining");
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
  		}

	});
});
