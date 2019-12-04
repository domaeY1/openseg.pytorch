#!/usr/bin/env bash

# check the enviroment info
nvidia-smi
PYTHON="/root/miniconda3/bin/python"
${PYTHON} -m pip install yacs
${PYTHON} -m pip install torchcontrib
${PYTHON} -m pip install pydensecrf

export PYTHONPATH="/msravcshare/yuyua/code/segmentation/openseg.pytorch":$PYTHONPATH

cd ../../

DATA_DIR="/msravcshare/dataset/pascal_voc"
SAVE_DIR="/msravcshare/dataset/seg_result/pascal_voc/"
BACKBONE="hrnet48"
CONFIGS="configs/pascal_voc/H_48_D_4.json"
CONFIGS_TEST="configs/pascal_voc/H_48_D_4_test.json"

MODEL_NAME="hrnet48_asp_ocr"
LOSS_TYPE="fs_auxce_loss"

CHECKPOINTS_NAME="${MODEL_NAME}_${BACKBONE}_"$2
LOG_FILE="./log/pascal_voc/${CHECKPOINTS_NAME}.log"

PRETRAINED_MODEL="./pretrained_model/hrnetv2_w48_imagenet_pretrained.pth"
MAX_ITERS=60000


if [ "$1"x == "train"x ]; then
  ${PYTHON} -u main.py --configs ${CONFIGS} --drop_last y --nbb_mult 10 \
                       --phase train --gathered n --loss_balance y --log_to_file n \
                       --backbone ${BACKBONE} --model_name ${MODEL_NAME} --gpu 0 1 2 3 \
                       --data_dir ${DATA_DIR} --loss_type ${LOSS_TYPE} --max_iters ${MAX_ITERS} \
                       --checkpoints_name ${CHECKPOINTS_NAME} --pretrained ${PRETRAINED_MODEL} \
                       > ${LOG_FILE} 2>&1

elif [ "$1"x == "resume"x ]; then
  ${PYTHON} -u main.py --configs ${CONFIGS} --drop_last y --nbb_mult 10 \
                       --phase train --gathered n --loss_balance y --log_to_file n \
                       --backbone ${BACKBONE} --model_name ${MODEL_NAME} --max_iters ${MAX_ITERS} \
                       --data_dir ${DATA_DIR} --loss_type ${LOSS_TYPE} --gpu 0 1 2 3 \
                       --resume_continue y --resume ./checkpoints/pascal_voc/${CHECKPOINTS_NAME}_latest.pth \
                       --checkpoints_name ${CHECKPOINTS_NAME} --pretrained ${PRETRAINED_MODEL} \
                       >> ${LOG_FILE} 2>&1

elif [ "$1"x == "debug"x ]; then
  ${PYTHON} -u main.py --configs ${CONFIGS} --drop_last y \
                       --phase debug --gpu 0 --log_to_file n  > ${LOG_FILE} 2>&1


elif [ "$1"x == "val"x ]; then
  ${PYTHON} -u main.py --configs ${CONFIGS_TEST} --drop_last n \
                       --backbone ${BACKBONE} --model_name ${MODEL_NAME} --checkpoints_name ${CHECKPOINTS_NAME} \
                       --phase test --gpu 0 1 2 3 --resume ./checkpoints/pascal_voc/${CHECKPOINTS_NAME}_latest.pth \
                       --data_dir ${DATA_DIR} \
                       --out_dir ${SAVE_DIR}${CHECKPOINTS_NAME}_val_ms_5x

  cd lib/metrics
  ${PYTHON} -u ade20k_evaluator.py --configs ../../${CONFIGS_TEST} \
                                   --pred_dir ${SAVE_DIR}${CHECKPOINTS_NAME}_val_ms_5x/label/ \
                                   --gt_dir ${DATA_DIR}/val/label  

  # ${PYTHON} -u main.py --configs ${CONFIGS} --drop_last n \
  #                      --backbone ${BACKBONE} --model_name ${MODEL_NAME} --checkpoints_name ${CHECKPOINTS_NAME} \
  #                      --phase test --gpu 0 1 2 3 --resume ./checkpoints/pascal_voc/${CHECKPOINTS_NAME}_latest.pth \
  #                      --data_dir ${DATA_DIR} \
  #                      --out_dir ${SAVE_DIR}${CHECKPOINTS_NAME}_val_ss

  # cd lib/metrics
  # ${PYTHON} -u ade20k_evaluator.py --configs ../../${CONFIGS} \
  #                                  --pred_dir ${SAVE_DIR}${CHECKPOINTS_NAME}_val_ss/label/ \
  #                                  --gt_dir ${DATA_DIR}/val/label 




elif [ "$1"x == "test"x ]; then
  ${PYTHON} -u main.py --configs ${CONFIGS} --drop_last y \
                       --backbone ${BACKBONE} --model_name ${MODEL_NAME} --checkpoints_name ${CHECKPOINTS_NAME} \
                       --phase test --gpu 0 --resume ./checkpoints/pascal_voc/${CHECKPOINTS_NAME}_latest.pth \
                       --test_dir ${DATA_DIR}/test --log_to_file n --out_dir test >> ${LOG_FILE} 2>&1

else
  echo "$1"x" is invalid..."
fi