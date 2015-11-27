
//打开字划入效果
window.onload = function(){
    $(".connect p").eq(0).animate({ "left": "0%" }, 600);
    $(".connect p").eq(1).animate({ "left": "0%" }, 400);
};
//jquery.validate表单验证
$(document).ready(function(){

	var loginApi = getUrlParam("loginApi");
    var registApi = getUrlParam("registApi");
    document.getElementById("privacy").onclick = function(){
    	controller.showPrivacy();
    };
    document.getElementById("login").onclick = function(){
        window.location.href = "login_" + lang + ".html?loginApi=" + loginApi + "&registApi=" + registApi;
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

			controller.showToastActivity("REGISTING");
			//hash password
         	var originPsw = form.password.value;
            var shaObj = new jsSHA("SHA-256", "TEXT");
			shaObj.update(originPsw);
			var hash = shaObj.getHash("HEX");
			$("#password").val(hash);
			var formData = $("#registerForm").serialize();
			$("#password").val(originPsw);
  			$.ajax({
  				cache:false,
                type: "POST",
                url:registApi,
                data:formData,
                async:true,
                error: function(request) {
					controller.hideActivity();
                    controller.alert("CONNECT_ERROR");
                },
                success: function(result){
					controller.hideActivity();
					if (result.suc == true){
						controller.finishRegist(result.accountId+"#p"+result.accountName);
					}else if (result.msg) {
						controller.alert(result.msg);
					}
				}
			});
  		}
	});
});
