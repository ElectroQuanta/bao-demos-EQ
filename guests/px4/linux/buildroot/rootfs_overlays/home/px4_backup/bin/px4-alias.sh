#!/bin/sh

# File is auto-generated by cmake compilation, do not edit.
R="`pwd`/"

# Map the NuttX-style variable definition 'set <var> <value>' to something that
# bash and alternatives understand
# define _set first because sh (POSIX shell) does not like overwriting set directly
_set() {
	eval $1=\"$2\"
}
alias set=_set

# Don't stop on errors.
#set -e

# Arguments passed to this script:
# $1: optional instance id
px4_instance=0
[ -n "$1" ] && px4_instance=$1

alias cdev_test='px4-cdev_test --instance $px4_instance'
alias controllib_test='px4-controllib_test --instance $px4_instance'
alias rc_tests='px4-rc_tests --instance $px4_instance'
alias uorb_tests='px4-uorb_tests --instance $px4_instance'
alias wqueue_test='px4-wqueue_test --instance $px4_instance'
alias ads1115='px4-ads1115 --instance $px4_instance'
alias ms5611='px4-ms5611 --instance $px4_instance'
alias batt_smbus='px4-batt_smbus --instance $px4_instance'
alias camera_trigger='px4-camera_trigger --instance $px4_instance'
alias ms4525do='px4-ms4525do --instance $px4_instance'
alias ms5525dso='px4-ms5525dso --instance $px4_instance'
alias sdp3x='px4-sdp3x --instance $px4_instance'
alias cm8jl65='px4-cm8jl65 --instance $px4_instance'
alias gy_us42='px4-gy_us42 --instance $px4_instance'
alias leddar_one='px4-leddar_one --instance $px4_instance'
alias lightware_laser_i2c='px4-lightware_laser_i2c --instance $px4_instance'
alias lightware_laser_serial='px4-lightware_laser_serial --instance $px4_instance'
alias lightware_laser_test='px4-lightware_laser_test --instance $px4_instance'
alias ll40ls='px4-ll40ls --instance $px4_instance'
alias mb12xx='px4-mb12xx --instance $px4_instance'
alias srf02='px4-srf02 --instance $px4_instance'
alias teraranger='px4-teraranger --instance $px4_instance'
alias tf02pro='px4-tf02pro --instance $px4_instance'
alias tfmini='px4-tfmini --instance $px4_instance'
alias ulanding_radar='px4-ulanding_radar --instance $px4_instance'
alias vl53l0x='px4-vl53l0x --instance $px4_instance'
alias vl53l1x='px4-vl53l1x --instance $px4_instance'
alias gps='px4-gps --instance $px4_instance'
alias icm42605='px4-icm42605 --instance $px4_instance'
alias icm42688p='px4-icm42688p --instance $px4_instance'
alias hmc5883='px4-hmc5883 --instance $px4_instance'
alias ist8310='px4-ist8310 --instance $px4_instance'
alias qmc5883l='px4-qmc5883l --instance $px4_instance'
alias pca9685_pwm_out='px4-pca9685_pwm_out --instance $px4_instance'
alias crsf_rc='px4-crsf_rc --instance $px4_instance'
alias rc_input='px4-rc_input --instance $px4_instance'
alias batmon='px4-batmon --instance $px4_instance'
alias airspeed_selector='px4-airspeed_selector --instance $px4_instance'
alias attitude_estimator_q='px4-attitude_estimator_q --instance $px4_instance'
alias battery_status='px4-battery_status --instance $px4_instance'
alias camera_feedback='px4-camera_feedback --instance $px4_instance'
alias commander='px4-commander --instance $px4_instance'
alias control_allocator='px4-control_allocator --instance $px4_instance'
alias dataman='px4-dataman --instance $px4_instance'
alias ekf2='px4-ekf2 --instance $px4_instance'
alias send_event='px4-send_event --instance $px4_instance'
alias flight_mode_manager='px4-flight_mode_manager --instance $px4_instance'
alias fw_att_control='px4-fw_att_control --instance $px4_instance'
alias fw_autotune_attitude_control='px4-fw_autotune_attitude_control --instance $px4_instance'
alias fw_pos_control='px4-fw_pos_control --instance $px4_instance'
alias fw_rate_control='px4-fw_rate_control --instance $px4_instance'
alias gimbal='px4-gimbal --instance $px4_instance'
alias gyro_calibration='px4-gyro_calibration --instance $px4_instance'
alias gyro_fft='px4-gyro_fft --instance $px4_instance'
alias land_detector='px4-land_detector --instance $px4_instance'
alias landing_target_estimator='px4-landing_target_estimator --instance $px4_instance'
alias load_mon='px4-load_mon --instance $px4_instance'
alias local_position_estimator='px4-local_position_estimator --instance $px4_instance'
alias logger='px4-logger --instance $px4_instance'
alias mag_bias_estimator='px4-mag_bias_estimator --instance $px4_instance'
alias manual_control='px4-manual_control --instance $px4_instance'
alias mavlink='px4-mavlink --instance $px4_instance'
alias mavlink_tests='px4-mavlink_tests --instance $px4_instance'
alias mc_att_control='px4-mc_att_control --instance $px4_instance'
alias mc_autotune_attitude_control='px4-mc_autotune_attitude_control --instance $px4_instance'
alias mc_hover_thrust_estimator='px4-mc_hover_thrust_estimator --instance $px4_instance'
alias mc_pos_control='px4-mc_pos_control --instance $px4_instance'
alias mc_rate_control='px4-mc_rate_control --instance $px4_instance'
alias navigator='px4-navigator --instance $px4_instance'
alias rc_update='px4-rc_update --instance $px4_instance'
alias rover_pos_control='px4-rover_pos_control --instance $px4_instance'
alias sensors='px4-sensors --instance $px4_instance'
alias pwm_out_sim='px4-pwm_out_sim --instance $px4_instance'
alias sensor_baro_sim='px4-sensor_baro_sim --instance $px4_instance'
alias sensor_gps_sim='px4-sensor_gps_sim --instance $px4_instance'
alias sensor_mag_sim='px4-sensor_mag_sim --instance $px4_instance'
alias simulator_sih='px4-simulator_sih --instance $px4_instance'
alias temperature_compensation='px4-temperature_compensation --instance $px4_instance'
alias vtol_att_control='px4-vtol_att_control --instance $px4_instance'
alias bsondump='px4-bsondump --instance $px4_instance'
alias dyn='px4-dyn --instance $px4_instance'
alias led_control='px4-led_control --instance $px4_instance'
alias param='px4-param --instance $px4_instance'
alias perf='px4-perf --instance $px4_instance'
alias sd_bench='px4-sd_bench --instance $px4_instance'
alias shutdown='px4-shutdown --instance $px4_instance'
alias tests='px4-tests --instance $px4_instance'
alias hrt_test='px4-hrt_test --instance $px4_instance'
alias listener='px4-listener --instance $px4_instance'
alias tune_control='px4-tune_control --instance $px4_instance'
alias uorb='px4-uorb --instance $px4_instance'
alias ver='px4-ver --instance $px4_instance'
alias work_queue='px4-work_queue --instance $px4_instance'
alias fake_gps='px4-fake_gps --instance $px4_instance'
alias fake_imu='px4-fake_imu --instance $px4_instance'
alias fake_magnetometer='px4-fake_magnetometer --instance $px4_instance'
alias hello='px4-hello --instance $px4_instance'
alias px4_mavlink_debug='px4-px4_mavlink_debug --instance $px4_instance'
alias px4_simple_app='px4-px4_simple_app --instance $px4_instance'
alias work_item_example='px4-work_item_example --instance $px4_instance'
