
//打开字划入效果
window.onload = function(){
    $(".connect p").eq(0).animate({"left":"0%"}, 600);
    $(".connect p").eq(1).animate({"left":"0%"}, 400);

    
};
//jquery.validate表单验证
$(document).ready(function(){

	var loginApi = getUrlParam("loginApi");
    var registApi = getUrlParam("registApi");
    
    document.getElementById("login").onclick = function(){
        window.location.href = "login.html?loginApi=" + loginApi + "&registApi=" + registApi;
        return false;
    }
    
	//注册表单验证
	$("#registerForm").validate({
		rules:{
			username:{
				required:true,//必填
				minlength:2, //最少6个字符
				maxlength:23,//最多20个字符
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
			controller.showToastActivity("Regsting");
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
					controller.hideToastActivity();
                    controller.makeToast("Connection error");
                },
                success: function(result){
					controller.hideToastActivity();
					if (result.suc == true){
						controller.alert("注册成功，请记住您的Sharelink ID:\n" + result.accountId);
						controller.finishRegist(result.accountId+"#p"+result.accountName);
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
